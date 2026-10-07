# Known Limitations

This snapshot is for local demonstration and code review. Running tests does not
make it a production-ready transportation or payment service.

## Before Any Public Service

- Audit authorization and object ownership on every REST endpoint and SignalR method.
- Extend the [two-process PostgreSQL checks](POSTGRES_DISPATCH.md) to production load,
  failover and all legacy state transitions. A global advisory lock now protects demo
  matching and controller writes, with relational uniqueness and rollback tests.
  InMemory remains process-local; notifications are not a transactional outbox and
  cross-instance SignalR delivery needs a backplane.
- Validate live payment state transitions, webhook signatures, idempotency, refunds,
  and reconciliation. The demo bypasses external charging.
- Review password handling, session refresh, brute-force defenses, CORS, rate limits,
  sensitive logging, and retention of identity/location data.
- Add incremental PostgreSQL migrations before using any existing database. The optional
  isolated PostgreSQL mode uses `EnsureCreated` for a fresh synthetic schema, including
  `DispatchCursor`, `Payment.CashAmount` and uniqueness constraints; it is not a migration.
- Continue dependency advisory monitoring; a clean registry audit is not a code security audit.
- Configure supported routing/tile, messaging, monitoring, backup, and hosting services.
- Revalidate platform-specific permissions and release signing on physical devices.

## What the Tests Do Not Establish

- Fleet-scale dispatch optimization, load capacity, or multi-instance guarantees beyond
  the specific synthetic concurrency/recovery scenarios in the PostgreSQL harness.
- Recovery from SignalR disconnects, duplicate events, or missed trip updates.
- Current airport licensing rules or regulatory compliance.
- Production migrations, real-card settlement, or live SMS delivery.
- Server-side token revocation when an operator signs out without a network connection.

## Publication Review

The source preflight checks known credential patterns and private configuration
filenames. It does not prove that all secrets, personal data, licensed assets, or
third-party rights have been identified. Review the staged Git diff and rights
before publishing. Real configuration, previous cloud deployment metadata, and
generated build output are excluded from the prepared snapshot.
