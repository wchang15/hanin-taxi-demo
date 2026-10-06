# Hanin Taxi API

ASP.NET Core API for the local-only rider, driver, and dispatcher demonstration.
The prepared snapshot targets .NET 10 and EF Core 10. Its original team-built
implementation and subsequent updates are documented in [contribution scope](../docs/CONTRIBUTIONS.md).

Run from the repository root with `node scripts/start-demo.mjs`.

The dispatcher uses deterministic eligibility rules and heuristic scoring, not
machine learning. Begin with [DispatchScoringService](Services/DispatchScoringService.cs),
[its tests](../tests/HaninTaxi.Tests/DispatchScoringTests.cs), and the
[architecture walkthrough](../docs/ARCHITECTURE.md).

Demo data is ephemeral. This copy refuses non-demo startup. PostgreSQL migrations,
live payments, external messaging, and production security require separate validation.
