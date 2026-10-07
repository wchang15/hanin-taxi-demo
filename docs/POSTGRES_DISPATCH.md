# Two-Process PostgreSQL Dispatch Verification

This is an October 2026 AI-assisted extension of the portfolio demo, not a claim
about the original deployment or production fleet scale. The default demo still
uses InMemory. This optional path uses a real, disposable PostgreSQL database.

## Run

Use .NET 10 and a PostgreSQL 17 server listening on loopback. The test database
account needs permission to create and drop databases. Use a dedicated test server,
not a production database account. No Stripe, Twilio or cloud account is required.

```bash
dotnet build backend --configuration Release
export HANIN_TEST_POSTGRES='Host=127.0.0.1;Port=5432;Database=postgres;Username=postgres'
# Supply PGPASSWORD through your local environment if the test server requires it.
dotnet run --project tests/HaninTaxi.PostgresChecks --configuration Release -- "$PWD"
```

The harness creates a randomly named `hanin_demo_checks_*` database, starts two
independent API OS processes on ephemeral loopback ports, and removes only its own
database in `finally`. Both processes share one randomly generated JWT signing key.
Test JWTs represent synthetic rider/driver/company identities; this suite does not test
the password/login workflow. The usual isolated API suite covers that separately.
An interrupted harness can leave a `hanin_demo_checks_*` database for manual cleanup.

The `postgres-dispatch` GitHub Actions job runs the same harness against a PostgreSQL
17 service. Merely adding the workflow does not establish that its run passed.

## Transaction Boundary

- [DispatchTransaction](../backend/Services/DispatchTransaction.cs) begins a
  Read Committed transaction, then acquires one transaction-scoped advisory lock
  **before reading state**. Independent processes use the same key.
- Matching saves both pending queues and the company cursor, then commits. Failure
  or disposal rolls back the entire attempt. The cursor survives API restart.
- [DemoDatabaseTransactionFilter](../backend/Services/DemoDatabaseTransactionFilter.cs)
  wraps legacy controller actions, including GET actions that write. Acceptance,
  decline, cancellation, enqueue and removal therefore use the same lock. An action
  exception or non-success result rolls back even earlier `SaveChanges` calls.
- The dispatch endpoint owns its separate context/transaction and is excluded from
  the filter to avoid nested-lock deadlock. The background matcher uses that same
  dispatch service. InMemory retains its existing process-local matching gate.
- Unique database indexes prohibit two driver queues referencing the same trip or
  customer queue, independently of the cooperative advisory lock.
- A five-second lock timeout, eight-second statement timeout and ten-second idle
  transaction timeout bound waiting and abandoned transactions. Killing the API
  does not imply PostgreSQL immediately detects a disconnected client; the failure
  test waits for bounded cleanup before asserting rollback and recovery.

## Thirty-Nine Assertions

The executable checks simultaneous API startup; `A1 -> B1 -> A2 -> B2`; 16 concurrent
dispatch requests with four unique offers; persisted queue order; an injected DB
failure and rollback; matching after failure; restart continuation; killing an API
inside a transaction and surviving-instance recovery; both orderings of concurrent
accept/cancel; removal of pending offers on cancellation; cross-instance decline;
atomic decline history/state; duplicate acceptance; and both unique constraints.
Database lock barriers make acceptance/cancellation race ordering deterministic.
No test relies only on two services inside the same process.

The original 20 dispatch assertions are followed by 19 realtime and ownership
checks. Real SignalR clients verify authenticated rider, driver and operator groups,
rejection of foreign groups and anonymous/invalid tokens, hub-only query tokens,
and removal of client-controlled broadcasting. Another company's operator cannot
change trip notes/prices or cancel the trip.

A deferred PostgreSQL constraint trigger deliberately fails **at commit**, after
the action's `SaveChanges` and notification enqueue. The driver's actual WebSocket
must not receive that rolled-back note. A subsequent successful update provides
a delivery barrier: its handler reads the committed note directly from PostgreSQL.
This checks post-commit delivery on one instance, not a cross-instance backplane.

## Deliberate Limits

One fleet-wide lock serializes work. This validates correctness for a small demo,
**not** throughput, horizontal scalability or production availability. Legacy reads
are also serialized conservatively because some GET actions mutate state. A future
command/query separation can reduce that scope without allowing uncoordinated writers.

Only a fresh synthetic schema is supported: `EnsureCreated` includes the current
cursor/cash fields and constraints; it does not apply incremental migrations to an
existing database. Never point this mode at an original deployment. The API requires
`DemoMode=true`, `Demo:Postgres=true`, a loopback `ConnectionStrings:DemoPostgres`,
and a database name starting `hanin_demo_`. External charging and messaging remain
disabled by demo mode. The app never drops a database; only the test harness drops
the random one it creates.

Controller notifications now buffer in the request scope until successful database
commit; failures discard them. Delivery failure after commit is logged without
turning the committed command into an HTTP error. This is **not a durable outbox**:
a process crash after commit can still lose the event. Cross-instance subscriber
delivery is not established; a backplane remains necessary. Full
authorization review, production migrations, real payments, load/failover tests and
all possible legacy state transitions remain separate work. Advisory locks protect
participating writers, not arbitrary SQL or new code that ignores the boundary.
