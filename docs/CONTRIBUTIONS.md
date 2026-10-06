# Contribution Scope

## Original Product

Woochang Chang founded the venture during graduate school, recruited one React
engineer, one Flutter engineer, and one Figma designer, and led planning,
coordination, and workflow testing. His confirmed hands-on contribution includes
API work, selected Flutter/React implementation, and review of the team's code.

The implementation was collaborative. This repository begins with a source
snapshot of that team-built product. Contribution descriptions reflect confirmed
responsibilities; its Git history records the preparation and maintenance of this
snapshot rather than the original development timeline.

The platform was submitted as an M.S. capstone, followed by continued work at
World Bankcard. The product reached internal testing and demonstration.

## October 2026 Engineering Review

The current restoration and review were carried out with AI coding assistance.
The accompanying tests and commands let a reviewer inspect the results directly.

- Restored local rider, driver, and dispatcher workflows with synthetic accounts.
- Separated route overview from idle-pickup camera framing.
- Rejected stale and out-of-order route responses and canceled superseded map animations.
- Added regression coverage for camera bounds and asynchronous route lifecycle.
- Reviewed dispatch eligibility; added company isolation and waiting-state guards.
- Reproduced dispatch failures before fixing them and added backend unit tests.
- Updated the prepared backend to .NET 10 and compatible EF Core/provider packages.
- Added isolated API checks for trip completion and quote-to-settlement consistency.
- Corrected cash-fare accounting and rounded quotes before payment confirmation.
- Prepared a source preflight, CI configuration, and documented known limitations.
- Replaced the operator's legacy build toolchain with Vite and updated its router.
- Fixed sign-out persistence, offline sign-in handling, and mobile dispatch layout.
- Added a session regression test and desktop/mobile browser scenarios.

These changes are current maintenance work, not historical employment outcomes.

## Review Path

1. Start with the product walkthrough in the portfolio.
2. Open a linked implementation and its paired test in the root README.
3. Run the documented checks against the local demo.
4. Compare the verified behavior with the limitations and unresolved production risks.
