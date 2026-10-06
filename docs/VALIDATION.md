# Verification Record

Local results on October 6, 2026. Remote GitHub Actions results are recorded
separately from the local checks below.

## Executed Checks

| Check                                 | Result                        | Boundary                                                                                 |
| ------------------------------------- | ----------------------------- | ---------------------------------------------------------------------------------------- |
| .NET 10 Release build and xUnit tests | 29 passed                     | 24 dispatch cases and 5 fare/payment cases                                               |
| Isolated API flow                     | 10 checks passed              | Separate process, temporary loopback port, synthetic data, zero external charges         |
| Rider Flutter tests                   | 11 passed                     | Route request lifecycle, camera bounds, coordinate conversion, airport eligibility       |
| Driver Flutter tests                  | 3 passed                      | Location label and payment-type parsing                                                  |
| Operator Vite production build        | Passed                        | React 18, Vite 8.3.3, React Router 7.18.4                                                |
| Operator session regression           | 1 passed                      | Sign-out clears in-memory and persisted identity                                         |
| Operator Playwright suite             | 14 passed, 0 skipped, 0 flaky | Seven scenarios at desktop and mobile sizes; real built app and isolated API             |
| Source-pattern preflight              | No findings                   | Selected credential patterns and private-config filenames only                           |
| Backend NuGet vulnerability query     | No listed vulnerable packages | Current NuGet advisory data, including transitive dependencies                           |
| Operator npm audit                    | 0 listed vulnerabilities      | Full installed dependency tree, including development tooling; not a code security audit |

Test environment: macOS arm64, .NET SDK 10.0.401 / runtime 10.0.12,
Flutter 3.47.6 / Dart 3.13.5. Initial backend/API checks used Node.js 20.17.0;
operator checks used Node.js 24.19.0 and Playwright 1.63.0 with Chromium 153.
The owner launched the browser suite from Terminal after the agent sandbox blocked
Chromium process startup. The resulting JSON report confirmed 14 expected results,
zero unexpected results, zero skipped cases, and zero flaky cases in 12.8 seconds.
Linux CI uses Node.js 22 for shared checks and Node.js 24 for the operator job.

## Failures Reproduced Before Fixing

1. Dispatch tests: 10 of 24 cases initially failed because the scorer accepted
   non-waiting queues or a request associated with another company. Waiting-state
   and company-boundary guards made these cases pass.
2. API flow: cash settlement returned a zero full amount for a quoted $44.07 trip.
   Recording `CashAmount` corrected the missing amount without treating cash as a card charge.
3. API flow: the unrounded computed amount was `44.0698267824976`, while the displayed
   quote was $44.07. Rounding the shared quote getters before confirmation made the
   stored payment and displayed quote agree exactly.
4. Operator session test: sign-out nested `initialState` under a new property rather
   than clearing the active state, leaving identity and tokens persisted. The test
   failed before the reset correction and passed afterward.
5. Browser review: the Vite migration exposed incompatible deep CommonJS icon
   imports. Explicitly selecting MUI's ESM icon modules fixed the blank screen.
   At 390px width, dispatch actions also overflowed; responsive action wrapping
   restored access to the new-call form.

## Dependency Work

The backend was moved from .NET 6 / EF Core 7 to .NET 10 / EF Core 10.
Authentication, identity, PostgreSQL provider, mail, and Swagger dependencies were
updated. Unused older HTTP/SignalR, Azure, SQL Server, and RabbitMQ references were
removed. The shared framework supplies current ASP.NET Core/SignalR support.

The React project moved from Create React App to Vite 8 and React Router 7.
Unused Next.js, Faker, and unused integration packages were removed. JSX-bearing
files were mechanically renamed to `.jsx`; environment variables now use Vite's
explicit public prefix. An EventEmitter browser implementation preserves the
existing dispatch queue. Clean `npm ci` and full-tree `npm audit` report zero
listed vulnerabilities. CI now runs the audit, session test, build, and browser suite.

## Browser Coverage

- Anonymous access to a nested dashboard route returns to sign-in.
- Synthetic operator sign-in, dispatch loading, and direct-route reload.
- Opening a new-call form at desktop and mobile sizes.
- Incorrect-password recovery and successful retry.
- Network-error messaging leaves the sign-in form usable.
- Online sign-out clears stored identity and prevents protected-route access.
- Offline sign-out still clears the local session and exits the protected UI.

The suite does not place real taxi requests or establish complete dispatch CRUD
coverage. Mobile Chromium emulation is not physical iPhone/Safari testing.
Connected Chrome review additionally checked the mobile navigation and seeded
driver list. Screenshots are actual browser captures of synthetic data.

## Not Yet Verified

- A fresh native simulator build of this entire prepared snapshot against the updated
  .NET 10 API. Included screenshots show the previously restored iOS app.
- Production PostgreSQL schema/migrations, real-card payments, refunds, live messaging.
- Concurrency, reconnect recovery, duplicate events, and full authorization coverage.
- All third-party asset rights and a comprehensive secret/security audit.
- Inherited compiler/lint warnings and operator bundle-size optimization.

These are explicit follow-up items, not guarantees established by a passing build.
