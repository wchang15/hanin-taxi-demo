# Operator Dashboard

React interface for requests, driver assignments, and dispatch operations.
See the [root README](../README.md) for the shared demo and synthetic sign-in accounts.

```bash
npm ci
cp .env.example .env.local
npm start
```

The sample environment targets the local API at `127.0.0.1:5050`. This is a
Create React App codebase, not a Next.js application. Its inherited build tooling
requires further dependency modernization; the build check is not a security audit.

Use `npm run build` for the static production bundle. Do not connect this
demonstration to production customer, driver, or payment data.
