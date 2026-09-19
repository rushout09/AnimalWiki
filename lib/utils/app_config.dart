// Plain-Dart constants with no Flutter dependency, so pure-Dart code (the
// HTTP services, a `dart run` smoke script) can use them without pulling in
// dart:ui through package:flutter/material.dart.

// A new install starts with this many credits. A stored balance, including
// a stored 0, is never overwritten by this default.
const int kFreeStarterCredits = 2;

// The proxy that holds the Gemini key server-side and runs the prompts.
// See proxy/README.md. Overridable at build time with
// --dart-define=PROXY_BASE_URL=...
const String kProxyBaseUrl = String.fromEnvironment(
  'PROXY_BASE_URL',
  defaultValue: 'https://animalwiki-proxy-912119732546.us-central1.run.app',
);
