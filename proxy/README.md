# animalwiki-proxy

A small Cloud Run service between the Animal Identifier app and Gemini. The app used to carry a Gemini API key
inside its bundle, which anyone could pull out. Now the app calls this service and the key (or the service
account) stays on the server.

## What it accepts

Only three fixed requests. The prompts live in `src/prompts.mjs`, so the app cannot send its own text to the model.

| Request | Body | What it does |
|---|---|---|
| `POST /v1/classify` | `{"image": "<base64 photo>"}` | Human, animal or neither |
| `POST /v1/identify` | `{"image": "<base64 photo>"}` | Species and traits from the photo |
| `POST /v1/info` | `{"species": "...", "common_name": "...", "breed": "..."}` | Full animal profile (no photo) |
| `GET /health` | none | Health check |

Each answer is Google's own response JSON, so the app keeps reading `candidates[0].content.parts[0].text`.

## Checks before anything reaches Google

- JSON only, at most 3.5 MB, and the photo must really be a JPEG, PNG or WebP (checked by its first bytes).
- `/v1/info` names are limited to letters, digits and a few punctuation marks, at most 120 characters each.
- Upstream errors come back as a plain `502` or `504`, with no detail from Google.
- Logs hold the route, status and timing only, never the photo. Anything shaped like a Google key is redacted.

## Configuration

| Variable | Meaning |
|---|---|
| `GEMINI_MODEL` | Model id. Defaults to `gemini-3.5-flash-lite`. |
| `GEMINI_API_KEY` | Use the Gemini API with this key (Cloud Run fills it from Secret Manager). |
| `GCP_PROJECT` | Use Vertex AI with the service account this service runs as, and no key. Used only when there is no `GEMINI_API_KEY`. |
| `PORT` | Set by Cloud Run. |

## Develop

```bash
cd proxy
npm test
```

The tests use a fake upstream and cost nothing.
