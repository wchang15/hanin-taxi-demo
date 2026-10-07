# Hanin Taxi

[![Checks](https://github.com/wchang15/hanin-taxi-demo/actions/workflows/ci.yml/badge.svg)](https://github.com/wchang15/hanin-taxi-demo/actions/workflows/ci.yml)

A team-built rider, driver, and dispatcher platform, restored as a reproducible
local demonstration. Flutter clients share trip state with an ASP.NET Core API
and a React operator dashboard.

[Product case study](https://www.woochangchang.com/hanin-taxi.html) |
[Narrated workflow demo](https://www.woochangchang.com/hanin-taxi.html#demo) |
[Architecture](docs/ARCHITECTURE.md) |
[Dispatch and mapping decisions](docs/DISPATCH_AND_MAPPING.md) |
[Contribution scope](docs/CONTRIBUTIONS.md) |
[Verification](docs/VALIDATION.md)

<p>
  <img src="docs/images/rider-quote.png" width="220" alt="Actual iOS rider screen with Fort Lee-to-JFK route and a $44.07 quote" />
  <img src="docs/images/driver-pickup.png" width="220" alt="Actual iOS driver screen with an accepted pickup" />
</p>

Actual iOS simulator captures, using synthetic accounts in an internal-test environment.

The narrated demo connects rider request, driver acceptance, operator visibility,
and completion. It is an edited internal-test workflow, not passenger service.
The driver start/completion inserts were recaptured using the restored iOS client
against reviewed API revision `4b43179`, confirming the displayed `$44.07` cash fare.
No external payment was made. This does not replace a fresh native build of the
entire public snapshot. See [verification scope](docs/VALIDATION.md).

## Start Here

| Engineering question                        | Implementation                                                                                                             | Evidence                                                                                                                          |
| ------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| How do company turns stay fair?            | [CompanyDispatchService](backend/Services/CompanyDispatchService.cs)                                                     | [21 queue, failure, and concurrent-invocation cases](tests/HaninTaxi.Tests/CompanyDispatchTests.cs)                                |
| Which driver is eligible for a request?     | [DispatchScoringService](backend/Services/DispatchScoringService.cs)                                                       | [24 dispatch tests](tests/HaninTaxi.Tests/DispatchScoringTests.cs)                                                                |
| What if an old route arrives after a reset? | [TripController](rider-app/lib/controllers/trip_controller.dart)                                                           | [Delayed-response regression tests](rider-app/test/trip_route_request_test.dart)                                                  |
| How does a route avoid map controls?        | [Camera fitting](rider-app/lib/utils/route_camera.dart)                                                                    | [Viewport and inset tests](rider-app/test/route_camera_test.dart)                                                                 |
| Does settlement match the rider's quote?    | [Trip confirmation](backend/Controllers/TripController.cs), [payment completion](backend/Controllers/PaymentController.cs) | [Isolated demo API checks](scripts/test-demo.mjs)                                                                                 |
| Does sign-out remove stored identity?       | [Session store](admin-dashboard/src/store/userStore.js)                                                                    | [Persistence regression test](admin-dashboard/tests/session.test.mjs), [browser scenarios](admin-dashboard/e2e/operator.spec.mjs) |

## My Role

I founded Hanin Taxi during graduate school and contributed API, Flutter, and React
code alongside a React engineer, a Flutter engineer, and a Figma designer I recruited.
My work included:

- Designing company-round-robin dispatch while preserving each company's driver
  queue: `A1 -> B1 -> A2 -> B2`, after comparing it with nearest-driver assignment.
- Implementing regional pickup restrictions based on company operating boundaries.
- Developing the React admin driver-location map and manual dispatch workflows.
- Testing 5- and 10-second rider-map refresh intervals, selecting Mapbox for project
  cost constraints, and connecting driver navigation to Waze and Google Maps.
- Leading product planning, code review, and cross-interface workflow testing.

The team-built platform became my M.S. capstone. World Bankcard's interest led to
a full-time Software Engineer role exploring restaurant-delivery integration with
the dispatch platform. That integration remained exploratory, not a shipped service.

This snapshot separates the original team implementation from the October 2026
demo restoration and engineering review. The October review now implements company
rotation in both matching entry points, with queue and concurrent-invocation tests.
This is a new implementation of the historical policy, not recovered original code.
See [contribution scope](docs/CONTRIBUTIONS.md) and the
[dispatch/mapping decision record](docs/DISPATCH_AND_MAPPING.md) for that boundary,
current 30/5/10-second timers, and a sourced routing-cost example.

## Run the Local Demo

Prerequisites: .NET SDK 10, Node.js 22.12+ (22.x or 24+), Flutter 3.47.6 for the mobile apps,
and Xcode with an iOS simulator for iPhone testing.

From the repository root:

```bash
node scripts/start-demo.mjs
```

The server binds to `127.0.0.1:5050`, uses a new random signing key per launch,
and seeds an in-memory database. `PORT=5059` selects another port. `DOTNET_BIN`
can select a .NET executable that is not on PATH.

| Role       | Username        | Password   |
| ---------- | --------------- | ---------- |
| Rider      | `demo_customer` | `demo1234` |
| Driver     | `demo_driver`   | `demo1234` |
| Dispatcher | `demo_company`  | `demo1234` |

For the React dispatcher, in another terminal:

```bash
cd admin-dashboard
npm ci
cp .env.example .env.local
npm start
```

For the rider, in another terminal:

```bash
cd rider-app
flutter pub get
cp config/local.example.json config/local.json
flutter run -d "iPhone 17 Pro" --dart-define-from-file=config/local.json
```

The driver uses the same command from `driver-app`. Use `flutter devices` to find
your simulator's actual name. No Apple signing account is needed for the simulator.
Physical-device/LAN deployment is intentionally not configured in this snapshot.

The API flow works without paid-service credentials. A road-following rider route
requires your own Mapbox public token in the ignored `config/local.json`; add it
before running the app. Without it, the app does not draw a road route. OpenStreetMap tiles still require internet
and retain attribution. No live Stripe, Twilio, or database credentials are needed.

## Verify

```bash
# Source-pattern preflight, excluding generated files.
node scripts/check-public-source.mjs

# Backend build and dispatch rules, without external-service keys.
dotnet run --project tests/HaninTaxi.Tests --configuration Release

# Starts and stops its own API on a temporary loopback port.
node scripts/test-demo.mjs

# Run from each Flutter application directory.
flutter test

# Run from admin-dashboard.
npm ci
npm run audit
npm test
CI=true npm run build
npx playwright install chromium
npm run test:e2e
```

[GitHub Actions configuration](.github/workflows/ci.yml) repeats these checks.
The browser suite builds the actual operator app and starts a separate in-memory
API on port 5796 and frontend on port 4196. It refuses to reuse existing servers.
A workflow definition is not a claim that a remote run has passed. Local results
and unverified areas are recorded in [VALIDATION.md](docs/VALIDATION.md).

## Repository Map

| Directory          | Responsibility                                                      |
| ------------------ | ------------------------------------------------------------------- |
| `rider-app/`       | Booking, fare selection, map lifecycle, payment selection           |
| `driver-app/`      | Driver availability, acceptance, trip progress                      |
| `backend/`         | API, shared trip model, company rotation, eligibility, SignalR events |
| `admin-dashboard/` | React operator interface                                            |
| `tests/`           | Backend regression coverage                                         |
| `scripts/`         | Isolated demo runner, API verification, source preflight            |
| `docs/`            | Architecture, contribution boundaries, verification and limitations |

## Scope

This is a local-only engineering demo with synthetic data. The API refuses to
start outside demo mode. Review [known limitations](docs/LIMITATIONS.md) before
extending it or considering any public service deployment.

The snapshot preserves team-built code. No new open-source license or ownership
transfer is granted here; redistribution of original assets and third-party
components needs to respect their respective rights.
