// Two ways to reach Gemini. Each returns a function (body, signal) => Response.
// The handler does not care which one it gets.

const GEMINI_API = 'https://generativelanguage.googleapis.com/v1beta';
const VERTEX_API = 'https://aiplatform.googleapis.com/v1';
const METADATA_TOKEN_URL =
  'http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token';

// Gemini API with an API key (the key comes from an environment variable that
// Cloud Run fills from Secret Manager).
export function geminiApiUpstream({ apiKey, model, fetchImpl = fetch }) {
  return function call(body, signal) {
    return fetchImpl(`${GEMINI_API}/models/${model}:generateContent`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', 'x-goog-api-key': apiKey },
      body: JSON.stringify(body),
      signal,
    });
  };
}

// Vertex AI with the Cloud Run service account. No key exists in this mode: the
// token comes from the metadata server and is cached until shortly before expiry.
export function vertexUpstream({ project, model, fetchImpl = fetch, tokenUrl = METADATA_TOKEN_URL }) {
  let cached = null;

  async function token(signal) {
    if (cached && cached.expiresAt - Date.now() > 60_000) return cached.token;
    const r = await fetchImpl(tokenUrl, { headers: { 'Metadata-Flavor': 'Google' }, signal });
    if (!r.ok) throw new Error(`metadata token request failed with ${r.status}`);
    const j = await r.json();
    cached = { token: j.access_token, expiresAt: Date.now() + j.expires_in * 1000 };
    return cached.token;
  }

  return async function call(body, signal) {
    const t = await token(signal);
    const url = `${VERTEX_API}/projects/${project}/locations/global/publishers/google/models/${model}:generateContent`;
    return fetchImpl(url, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${t}` },
      body: JSON.stringify(body),
      signal,
    });
  };
}
