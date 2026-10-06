# Operator Dashboard

React interface for requests, driver assignments, and dispatch operations.
See the [root README](../README.md) for the shared demo and synthetic sign-in accounts.

```bash
npm ci
cp .env.example .env.local
npm start
```

Use Node.js 22.12+ (22.x or 24+). Vite serves the app on loopback and prints its
local URL. The sample environment targets the local API at `127.0.0.1:5050`.
The original React application now uses Vite 8 and React Router 7. The API and
SignalR addresses are public `VITE_*` settings; never put server secrets in them.
For an API on another port, update both addresses in the ignored `.env.local`.

## Verification

```bash
npm run audit
npm test
npm run build
npx playwright install chromium
npm run test:e2e
```

`npm test` checks that sign-out clears both in-memory and persisted identity.
Playwright covers seven scenarios at desktop and mobile sizes: anonymous route
protection, sign-in with nested-route reload, a new dispatch form, invalid-password
retry, network failure, sign-out, and offline sign-out. It uses the built app and
a separate synthetic API, never an existing server. Ports 4196 and 5796 must be free.
The suite also requires the .NET SDK; `DOTNET_BIN` can select its executable.

Results and screenshots stay under ignored `test-results/`. The E2E-specific
bundle stays in ignored `build-e2e/`, separate from the regular `build/` output.
See [the verification record](../docs/VALIDATION.md) for executed results and limits.

`npm run build` creates the static bundle in `build/`; `npm run preview` serves it
locally. A production bundle is not a production-service security certification.
Do not connect this demonstration to real customer, driver, or payment data.
