import { CLASSIFY_PROMPT, IDENTIFY_PROMPT, infoPrompt } from './prompts.mjs';

// Engineering limits. Mutable on purpose so tests can shrink them.
export const LIMITS = {
  maxBodyBytes: 3_500_000,
  upstreamTimeoutMs: 45_000,
  maxOutputTokens: { classify: 512, identify: 1024, info: 2048 },
  maxNameChars: 120,
};

const PATHS = { '/v1/classify': 'classify', '/v1/identify': 'identify', '/v1/info': 'info' };
const NAME_RE = /^[\p{L}\p{N} .,'’()\-\/×]+$/u;
const BASE64_RE = /^[A-Za-z0-9+/]+={0,2}$/;

class HttpError extends Error {
  constructor(status, code) {
    super(code);
    this.status = status;
    this.code = code;
  }
}

function redact(text) {
  return String(text).replace(/AIza[0-9A-Za-z_-]{20,}/g, '<redacted>');
}

function send(res, status, obj) {
  const body = JSON.stringify(obj);
  res.writeHead(status, { 'content-type': 'application/json', 'content-length': Buffer.byteLength(body) });
  res.end(body);
}

// Look only at the first bytes: enough to tell JPEG, PNG and WebP apart. The
// mime type the client claims is ignored.
function detectImage(b64) {
  const head = Buffer.from(b64.slice(0, 32), 'base64');
  if (head.length >= 3 && head[0] === 0xff && head[1] === 0xd8 && head[2] === 0xff) return 'image/jpeg';
  if (head.length >= 8 && head.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]))) {
    return 'image/png';
  }
  if (
    head.length >= 12 &&
    head.subarray(0, 4).toString('latin1') === 'RIFF' &&
    head.subarray(8, 12).toString('latin1') === 'WEBP'
  ) {
    return 'image/webp';
  }
  return null;
}

async function readJson(req) {
  const chunks = [];
  let size = 0;
  for await (const chunk of req) {
    size += chunk.length;
    if (size > LIMITS.maxBodyBytes) throw new HttpError(413, 'too_large');
    chunks.push(chunk);
  }
  try {
    return JSON.parse(Buffer.concat(chunks).toString('utf8'));
  } catch {
    throw new HttpError(400, 'bad_json');
  }
}

function imageParts(kind, body) {
  const image = body && body.image;
  if (typeof image !== 'string' || image.length < 16 || !BASE64_RE.test(image)) throw new HttpError(400, 'bad_image');
  const mimeType = detectImage(image);
  if (!mimeType) throw new HttpError(400, 'bad_image');
  const prompt = kind === 'classify' ? CLASSIFY_PROMPT : IDENTIFY_PROMPT;
  return [{ text: prompt }, { inlineData: { mimeType, data: image } }];
}

function cleanName(value, field, required) {
  if (value === undefined || value === null || value === '') {
    if (required) throw new HttpError(400, `bad_${field}`);
    return '';
  }
  if (typeof value !== 'string' || value.length > LIMITS.maxNameChars || !NAME_RE.test(value)) {
    throw new HttpError(400, `bad_${field}`);
  }
  return value.trim();
}

function infoParts(body, now) {
  const species = cleanName(body && body.species, 'species', true);
  const commonName = cleanName(body && body.common_name, 'common_name', true);
  const breed = cleanName(body && body.breed, 'breed', false);
  return [{ text: infoPrompt({ id: String(now()), species, commonName, breed }) }];
}

export function createHandler({ upstream, log, now = Date.now }) {
  return async function handle(req, res) {
    const started = now();
    let status = 500;
    let route = `${req.method} ${req.url}`;
    let upstreamStatus;
    let timer;
    try {
      let url;
      try {
        url = new URL(req.url, 'http://local');
      } catch {
        throw new HttpError(400, 'bad_request');
      }
      route = `${req.method} ${url.pathname}`;

      if (req.method === 'GET' && url.pathname === '/health') {
        status = 200;
        return send(res, 200, { ok: true });
      }
      const kind = PATHS[url.pathname];
      if (!kind) throw new HttpError(404, 'not_found');
      if (req.method !== 'POST') throw new HttpError(405, 'method_not_allowed');
      if (!/^application\/json\b/i.test(req.headers['content-type'] || '')) throw new HttpError(415, 'unsupported_media_type');
      if (Number(req.headers['content-length'] || 0) > LIMITS.maxBodyBytes) throw new HttpError(413, 'too_large');

      const body = await readJson(req);
      const parts = kind === 'info' ? infoParts(body, now) : imageParts(kind, body);
      const upstreamBody = {
        contents: [{ role: 'user', parts }],
        generationConfig: { responseMimeType: 'application/json', maxOutputTokens: LIMITS.maxOutputTokens[kind] },
      };

      const ac = new AbortController();
      timer = setTimeout(() => ac.abort(), LIMITS.upstreamTimeoutMs);
      let text;
      try {
        const r = await upstream(upstreamBody, ac.signal);
        upstreamStatus = r.status;
        text = await r.text();
        if (!r.ok) {
          log({ severity: 'WARNING', message: 'upstream_error', kind, upstreamStatus, detail: redact(text).slice(0, 300) });
          throw new HttpError(502, 'upstream_error');
        }
      } catch (e) {
        if (e instanceof HttpError) throw e;
        throw new HttpError(ac.signal.aborted ? 504 : 502, ac.signal.aborted ? 'upstream_timeout' : 'upstream_unreachable');
      }

      status = 200;
      res.writeHead(200, { 'content-type': 'application/json', 'content-length': Buffer.byteLength(text) });
      res.end(text);
    } catch (e) {
      if (e instanceof HttpError) {
        status = e.status;
        if (!res.headersSent) send(res, e.status, { error: e.code });
      } else {
        status = 500;
        log({ severity: 'ERROR', message: 'unexpected_error', detail: redact(e && e.message).slice(0, 300) });
        if (!res.headersSent) send(res, 500, { error: 'internal_error' });
      }
    } finally {
      clearTimeout(timer);
      log({ severity: 'INFO', message: 'request', route, status, ms: now() - started, upstreamStatus });
    }
  };
}
