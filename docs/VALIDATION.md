# Verification Record

Local results on October 6, 2026. GitHub Actions has not run for this repository;
the repository has not been published at the time this record was prepared.

## Executed Checks

| Check                                 | Result                        | Boundary                                                                           |
| ------------------------------------- | ----------------------------- | ---------------------------------------------------------------------------------- |
| .NET 10 Release build and xUnit tests | 29 passed                     | 24 dispatch cases and 5 fare/payment cases                                         |
| Isolated API flow                     | 10 checks passed              | Separate process, temporary loopback port, synthetic data, zero external charges   |
| Rider Flutter tests                   | 11 passed                     | Route request lifecycle, camera bounds, coordinate conversion, airport eligibility |
| Driver Flutter tests                  | 3 passed                      | Location label and payment-type parsing                                            |
| Operator `CI=true npm run build`      | Passed                        | Static compilation, not browser end-to-end coverage                                |
| Source-pattern preflight              | No findings                   | Selected credential patterns and private-config filenames only                     |
| Backend NuGet vulnerability query     | No listed vulnerable packages | Current NuGet advisory data, including transitive dependencies                     |
| Operator npm audit                    | 96 findings remain            | 3 low, 35 moderate, 58 high, 0 critical, including build/lint dependencies         |

Test environment: macOS arm64, .NET SDK 10.0.401 / runtime 10.0.12,
Flutter 3.47.6 / Dart 3.13.5, Node.js 20.17.0.
Linux CI jobs use Node.js 22 and remain unverified until the first remote run.

## Failures Reproduced Before Fixing

1. Dispatch tests: 10 of 24 cases initially failed because the scorer accepted
   non-waiting queues or a request associated with another company. Waiting-state
   and company-boundary guards made these cases pass.
2. API flow: cash settlement returned a zero full amount for a quoted $44.07 trip.
   Recording `CashAmount` corrected the missing amount without treating cash as a card charge.
3. API flow: the unrounded computed amount was `44.0698267824976`, while the displayed
   quote was $44.07. Rounding the shared quote getters before confirmation made the
   stored payment and displayed quote agree exactly.

## Dependency Work

The backend was moved from .NET 6 / EF Core 7 to .NET 10 / EF Core 10.
Authentication, identity, PostgreSQL provider, mail, and Swagger dependencies were
updated. Unused older HTTP/SignalR, Azure, SQL Server, and RabbitMQ references were
removed. The shared framework supplies current ASP.NET Core/SignalR support.

The React project did not import Next.js or Faker; these unused dependencies were
removed. Compatible npm audit updates were applied and the build rerun. Remaining
advisories include the inherited Create React App toolchain and router dependencies.
No `--force` downgrade to a placeholder `react-scripts` package was applied.

## Not Yet Verified

- A fresh native simulator build of this entire prepared snapshot against the updated
  .NET 10 API. Included screenshots show the previously restored iOS app.
- Production PostgreSQL schema/migrations, real-card payments, refunds, live messaging.
- Concurrency, reconnect recovery, duplicate events, and full authorization coverage.
- All third-party asset rights and a comprehensive secret/security audit.
- The remaining operator dependency advisories and inherited compiler/lint warnings.

These are explicit follow-up items, not guarantees established by a passing build.
