# TLS test fixtures (TEST-ONLY, throwaway)

`server_key.pem` / `server_cert.pem` are a self-signed pair generated ONLY to run
the local HTTPS test matrix (loopback 127.0.0.1) in `test/https_*_test.dart`.

- Never used by the app, never shipped in the APK, never a production credential.
- Only valid for `localhost`/loopback connections inside unit tests.
- Regenerate any time: see docs/TESTING.md (P1-7 section) for the openssl command.
- Presence in git is required so tests are reproducible for auditors.
