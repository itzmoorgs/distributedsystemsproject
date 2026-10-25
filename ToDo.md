# Distributed System Improvement To-do

This project is a local Docker Compose demonstration of a distributed three-tier catalog system. Items marked **local complete** are implemented and tested in this repository. Items marked **production follow-up** are not complete on a single Docker host.

## 1. Move beyond single-host Compose

- [ ] **Production follow-up:** Deploy across multiple nodes using Kubernetes or a managed container platform.
- [ ] **Production follow-up:** Route external traffic through a managed load balancer or ingress.
- [ ] **Production follow-up:** Use platform service discovery, health-based routing, automatic restarts, and replica scaling.
- [x] **Local complete:** Keep Docker Compose as the local development environment.
- [x] **Documented limitation:** Keepalived VIPs and the published presentation port do not provide host-level high availability in a single-host Compose deployment.

## 2. Remove single-instance data dependencies

- [ ] **Production follow-up:** Move MongoDB to a managed service or configure a properly operated replica set.
- [ ] **Production follow-up:** Move Redis to a managed service or configure Sentinel or Cluster high availability.
- [x] **Local complete:** Treat Redis as a persistent local cache; MariaDB remains the source of truth.
- [x] **Local complete:** Add MariaDB monitoring and backup/restore procedures.
- [x] **Local complete:** Execute and verify a local application-database restore. The restored catalog contained 12 products.

## 3. Make database routing cluster-aware

- [x] **Local complete:** Stop connecting application nodes directly to `galera1`.
- [x] **Local complete:** Add a database-aware HAProxy endpoint for failover and connection routing.
- [x] **Local complete:** Define write routing and read routing for the Galera cluster.
- [ ] **Production follow-up:** Complete connection-pool capacity testing as application replicas scale.

## 4. Improve cache behavior

- [x] **Local complete:** Define cache keys and TTLs for the catalog query.
- [x] **Local complete:** Provide scoped catalog-cache invalidation through the cache-clear endpoint.
- [ ] **Production follow-up:** Add cache-stampede protection for concurrent cache misses.
- [x] **Local complete:** Keep the cache-clear API scoped to the intended application cache key.

## 5. Add production observability

- [ ] **Production follow-up:** Instrument presentation, API, and database calls with OpenTelemetry.
- [ ] **Production follow-up:** Collect logs, metrics, and traces centrally.
- [ ] **Production follow-up:** Add dashboards and alerts for latency, errors, saturation, database health, and cache hit rate.
- [ ] **Production follow-up:** Implement distributed traces containing timings and cross-service spans instead of the current custom trace headers and UI.
- [x] **Local complete:** Review the current trace UI and service wiring in `web/catalog.js`, `application/index.js`, and the Compose configuration.

## 6. Tighten security and operations

- [x] **Local complete:** Create and use a least-privilege MongoDB application user instead of the MongoDB root account.
- [x] **Local complete:** Protect Redis with a password and keep it on the private database network.
- [x] **Local complete:** Keep real secrets outside checked-in environment files using `.env` and `.gitignore`.
- [ ] **Production follow-up:** Add TLS at the public ingress.
- [ ] **Production follow-up:** Add API authentication and rate limiting where appropriate.
- [ ] **Production follow-up:** Adopt a formal database migration system.
- [x] **Local complete:** Document operational, failover, backup, restore, and recovery procedures.

## Test evidence completed

- [x] Baseline service and health checks.
- [x] Galera baseline verification with three synchronized nodes.
- [x] MongoDB authentication and application-user verification.
- [x] Redis authentication verification.
- [x] ApacheBench Smoke test.
- [x] Web node failover test.
- [x] API node failover test.
- [x] Chaos Monkey web-node experiment.
- [x] Local application-database restore verification.
- [ ] Complete remaining pending load, Galera failure, Redis failure, MongoDB failure, Nagios, and diagram evidence before submission.

## Suggested production implementation order

1. **Production follow-up:** Migrate the single MongoDB and Redis instances to managed or replicated equivalents.
2. **Local complete:** Use the database-aware MariaDB endpoint and rerun the database failover tests.
3. **Production follow-up:** Move stateless web and API replicas to a multi-node scheduler.
4. **Production follow-up:** Implement distributed tracing instead of the current custom trace headers.
