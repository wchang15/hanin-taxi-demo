# Dispatch and Mapping Decisions

Confirmed with the project owner and checked against this snapshot on October 6, 2026.
Historical product decisions and current demo behavior are documented separately.

## Dispatch: Company Rotation, Then Driver Queue Order

The selected product policy was to alternate between companies while preserving
each company's driver order: `A1 -> B1 -> A2 -> B2`, rather than always selecting
the nearest driver. Traditional operators had drivers return to their company base
and wait their turn. The design accommodates that queue while distributing turns
across participating companies.

The trade-off is explicit: queue fairness can mean a longer pickup than a nearest-car
policy. Regional pickup eligibility still constrains assignment. No measured pickup-time
or fairness improvement is claimed.

## Executable Company Rotation

The October 2026 AI-assisted review adds
[CompanyDispatchService](../backend/Services/CompanyDispatchService.cs), shared by the
background worker and `POST /api/Demo/RunDispatch`. This implements the confirmed
product policy now; it is not evidence of the original team's exact algorithm.

1. Visit company IDs in ascending order, starting after the last company offered a trip
   and wrapping to the beginning. Company ID is a stable tie-break, not fleet size or distance.
2. Within that company, visit waiting drivers by queue creation time, then queue ID.
   Skip archived/missing drivers, the two-second enqueue/decline cooldown, and drivers
   with no eligible request. Skipped drivers keep their original queue timestamp.
3. For the first eligible driver, retain the existing distance/wait score to choose
   a customer, breaking ties by customer queue time and ID. That score cannot let
   a later driver or company jump the queue. Trips must still be matching and unassigned.
4. Mark both queues pending and save the last company ID in the same `SaveChangesAsync`
   call. A committed offer consumes a turn, whether later accepted or declined.
   Company-specific bookings stay in their own company and also consume a turn.
5. Skip empty/ineligible companies. No eligible pair means no cursor change. Declining
   retains the driver's queue position but excludes that request and applies cooldown;
   leaving and rejoining gets a new queue timestamp under the existing enqueue endpoint.

The singleton coordinator serializes its matching calls and loads each snapshot only
after taking the lock. A fresh context prevents failed saves from leaking tracked state
into a retry. The cursor survives request/service scopes while the demo database lives;
it does **not** survive an API process restart because storage is in-memory.

[21 coordinator tests](../tests/HaninTaxi.Tests/CompanyDispatchTests.cs) exercise rotation,
stable ties, uneven/empty queues, cooldown and eligibility skips, company isolation,
no-match cursor behavior, pre-save failure recovery, cancellation, shared endpoint state,
and overlapping matching invocations. The concurrency test pauses a save while other
calls enter, then checks unique driver/customer offers; it does not rely on lucky timing.

The optional [PostgreSQL verification mode](POSTGRES_DISPATCH.md) additionally wraps
matching and controller state transitions in transactions sharing a database advisory
lock. Its two-process harness checks concurrent offers, both accept/cancel orderings,
decline, duplicate acceptance, DB uniqueness, rollback and restart/crash recovery.
That mode persists the cursor across API restarts. The default InMemory behavior
described above is unchanged.

**Production boundary:** the global lock is intentionally conservative, not a
fleet-scale throughput design. Fresh-schema verification is not an incremental
production migration. Notifications still need an outbox/backplane, and broader
authorization, load and availability guarantees remain unverified.

## What Currently Refreshes, and When?

| Layer | Current behavior | Source |
| --- | --- | --- |
| Driver GPS/status | `STATUSUPDATE = 30` seconds. GPS acquisition and trip-status/location timers share this value. Startup, last-known and fresh fixes can also cause updates; this is not a guarantee of exactly one network request per 30 seconds. | [Constants](../driver-app/lib/utils/constants.dart), [location controller](../driver-app/lib/controllers/location_controller.dart), [trip controller](../driver-app/lib/controllers/trip_controller.dart) |
| Driver queue/trip polling | `POLLINGTIMER = 5` seconds. This checks application state, not a paid map refresh every five seconds. | [Driver trip controller](../driver-app/lib/controllers/trip_controller.dart) |
| Rider driver marker | Event-driven: a SignalR driver-location event changes the marker. During pickup, `setDriverLocation` also requests a route to the pickup. There is no independent five- or ten-second rider location-poll timer. | [Hub listener](../rider-app/lib/services/hub_service.dart), [trip controller](../rider-app/lib/controllers/trip_controller.dart) |
| Operator map | Schedules its next API fetch 10 seconds after the preceding fetch finishes. Manual refresh is also available. The API has no per-position GPS timestamp, so a recent fetch does not prove a fresh GPS fix. | [Map page](../admin-dashboard/src/pages/MapPage.jsx) |

The owner tested five- and ten-second rider-map updates during original development
and selected Mapbox because of mapping-cost constraints. The historical final interval,
invoice amount, and measured savings are not recoverable from that recollection.
Today's 30-second setting is a code observation, not a claim about the original experiment.

## A Location Update Is Not Automatically a Billable Map Request

GPS acquisition, an API coordinate upload, a SignalR message, a marker redraw,
map-tile loading, geocoding, and route calculation are different operations.
Only the provider service actually requested determines the mapping charge.

The rider currently calls Mapbox Directions through
[LocationController.getRoute](../rider-app/lib/controllers/location_controller.dart)
and [MapBoxService.getDirection](../rider-app/lib/services/mapbox_service.dart).
Pickup location events can therefore trigger billable route requests when a token
is configured. Marker rendering alone does not call Directions. The demo's default
base tiles are OpenStreetMap, not the Mapbox native mobile SDK. Address search goes
through the backend, which uses a synthetic catalog in demo mode and a Mapbox geocoding
integration otherwise. Map loading, search and routes must not be counted as one SKU.

Driver navigation opens Waze or Google Maps through
[DriverController](../driver-app/lib/controllers/driver_controller.dart), keeping
turn-by-turn navigation outside the platform. This is a product boundary, not proof
that all mapping costs disappear.

## Current Public Pricing Reference

Published USD pay-as-you-go rates checked October 6, 2026, not historical invoices:

| Routing service | Monthly free allowance | First paid tier | Next tier |
| --- | --- | --- | --- |
| [Mapbox Directions API](https://www.mapbox.com/pricing) | 100,000 requests | $2 / 1,000 requests, through 500,000 | $1.60 / 1,000, through 1,000,000 |
| [Google Compute Routes Essentials](https://developers.google.com/maps/billing-and-pricing/pricing) | 10,000 requests | $5 / 1,000 requests, through 100,000 | $4 / 1,000, through 500,000 |

Illustration only: assume 1,000 pickups per month, ten minutes of tracking per
pickup, one routing request per interval, no initial/retry requests, and no other
usage consuming the free allowance. This is not a benchmark or usage measurement.

| Routing interval | Requests / ten minutes | Monthly requests | Mapbox Directions | Google Routes Essentials |
| --- | ---: | ---: | ---: | ---: |
| 5 seconds | 120 | 120,000 | $40 | $530 |
| 10 seconds | 60 | 60,000 | $0 | $250 |
| 30 seconds | 20 | 20,000 | $0 | $50 |

For example, Google's 120,000-request estimate is `90,000 / 1,000 * $5 +
20,000 / 1,000 * $4`. Taxes, maps, search, backend hosting, contractual discounts
and feature differences are excluded. A longer interval reduces request volume,
but not necessarily the bill by the same percentage because of free allowances.
These rates cannot reconstruct the project's historical cost without its invoices.

## Next Engineering Decision

Decouple marker freshness from route recalculation: record timestamped locations,
measure actual Directions request volume, and evaluate a movement/time threshold
before rerouting. Test pickup ETA freshness and reconnect behavior before choosing
an interval. This is proposed work, not a feature claimed by this snapshot.
