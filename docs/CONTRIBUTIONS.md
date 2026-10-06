# Contribution Scope

## Original Product

Woochang Chang founded the venture during graduate school, recruited one React
engineer, one Flutter engineer, and one Figma designer. His responsibilities
combined hands-on API and selected Flutter/React development with product planning,
code review, and cross-interface workflow testing.

### Dispatch and Operator Workflows

- Evaluated nearby-driver matching against queue-based assignment for taxi companies
  whose drivers returned to the company base and waited their turn after trips.
- Implemented company-specific regional pickup restrictions, including a New Jersey
  operator's New York pickup constraint. These describe configured operating rules,
  not a comprehensive legal-compliance certification.
- Developed the React admin driver-location map and manual dispatch workflows.
  The snapshot's map fetches company driver positions, displays working status,
  and supports focusing on a driver. Operator-entered bookings feed the matching queue.

### Mapping and Navigation Decisions

- Tested 5- and 10-second rider-map refresh intervals to consider location freshness
  alongside mapping/service cost constraints.
- Selected Mapbox for the project's cost constraints and connected driver navigation
  to Waze and Google Maps rather than implementing turn-by-turn guidance in the platform.

These historical experiments are not the current runtime's refresh interval or a
measured cost-reduction claim. The October review replaced legacy sample markers
with API-only driver positions and 10-second polling, plus manual refresh. This is
polling, not continuous location streaming; the API has no per-position GPS timestamp.
The operator booking flow does not establish a direct driver-selection override.

The implementation was collaborative. This repository begins with a source
snapshot of that team-built product. Contribution descriptions reflect confirmed
responsibilities; its Git history records the preparation and maintenance of this
snapshot rather than the original development timeline.

The platform was submitted as an M.S. capstone. World Bankcard's interest led to a
full-time Software Engineer role exploring integration with its restaurant application
for delivery. That integration remained exploratory. The platform reached internal
testing and demonstration, not commercial passenger adoption.

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
- Removed sample drivers and HTML popup interpolation; added stable markers,
  API position validation, non-overlapping polling, and map error/empty states.

These changes are current maintenance work, not historical employment outcomes.

## Review Path

1. Start with the product walkthrough in the portfolio.
2. Open a linked implementation and its paired test in the root README.
3. Run the documented checks against the local demo.
4. Compare the verified behavior with the limitations and unresolved production risks.
