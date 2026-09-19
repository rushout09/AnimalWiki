import http from 'node:http';
import { createHandler } from './handler.mjs';
import { geminiApiUpstream, vertexUpstream } from './upstream.mjs';

const model = process.env.GEMINI_MODEL || 'gemini-3.5-flash-lite';
const port = Number(process.env.PORT || 8080);

function log(entry) {
  console.log(JSON.stringify(entry));
}

// GEMINI_API_KEY picks the Gemini API. GCP_PROJECT (without a key) picks Vertex AI
// with the service account this service runs as.
function pickUpstream() {
  if (process.env.GEMINI_API_KEY) {
    log({ severity: 'INFO', message: 'upstream', mode: 'gemini-api', model });
    return geminiApiUpstream({ apiKey: process.env.GEMINI_API_KEY, model });
  }
  if (process.env.GCP_PROJECT) {
    log({ severity: 'INFO', message: 'upstream', mode: 'vertex', model, project: process.env.GCP_PROJECT });
    return vertexUpstream({ project: process.env.GCP_PROJECT, model });
  }
  log({ severity: 'ERROR', message: 'no upstream configured: set GEMINI_API_KEY or GCP_PROJECT' });
  return async () => {
    throw new Error('no upstream configured');
  };
}

const handle = createHandler({ upstream: pickUpstream(), log });
const server = http.createServer((req, res) => {
  handle(req, res).catch((e) => {
    log({ severity: 'ERROR', message: 'handler_crashed', detail: String(e && e.message).slice(0, 200) });
    if (!res.headersSent) res.writeHead(500, { 'content-type': 'application/json' });
    res.end('{"error":"internal_error"}');
  });
});
server.requestTimeout = 60_000;
server.headersTimeout = 20_000;
server.listen(port, () => log({ severity: 'INFO', message: 'listening', port }));
process.on('SIGTERM', () => server.close(() => process.exit(0)));
