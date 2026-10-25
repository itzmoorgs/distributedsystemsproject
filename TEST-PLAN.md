# Resilience, HA, Failover and Performance Test Plan

## Project

Distributed three-tier catalog system using Docker Compose.

## Test environment

- Main stack: `docker-compose.main.yml`
- Test stack: `docker-compose.lab.yml`
- Public application: `http://localhost/`
- Test dashboard: `http://localhost:8090/`
- Nagios: `http://localhost:8088/`
- Evidence directory: `evidence/`

## Acceptance targets

- API health returns HTTP 200.
- Galera has three nodes in `Primary` state when healthy.
- Galera nodes report `Synced` state.
- One web or API node can fail while remaining nodes continue serving traffic.
- The database proxy routes application traffic to healthy Galera nodes.
- Smoke test has zero failed requests.
- Chaos experiments have a documented hypothesis and measured result.
- Backups are restored successfully before submission.

## 1. Baseline and functional checks

### Commands

```powershell
docker compose -f docker-compose.main.yml ps
Invoke-WebRequest -UseBasicParsing http://localhost/api/health
Read `MARIADB_ROOT_PASSWORD` from the local `.env` file, then run the Galera status command without committing the password to this document.
Read `REDIS_PASSWORD` from the local `.env` file, then run the Redis ping command without committing the password to this document.
```

### Verified baseline results

| Check | Result | Evidence |
|---|---|---|
| Main services | Pass; services were running | `evidence/baseline-services.txt` |
| API health | Pass; `{"status":"ok"}` | `evidence/baseline-api-health.json` |
| Galera cluster size | Pass; size 3 | `evidence/baseline-galera.txt` |
| Galera cluster status | Pass; Primary | `evidence/baseline-galera.txt` |
| Galera local state | Pass; Synced | `evidence/baseline-galera.txt` |
| Redis ping | Pass; PONG | `evidence/baseline-redis.txt` |
| MongoDB ping | Pass; `{ ok: 1 }` | `evidence/mongodb-ping.txt` |
| MongoDB application user | Pass; `store_app` has `readWrite` on `store_reviews` | `evidence/mongodb-users.txt` |

### Pending baseline checks

- [ ] Confirm round-robin web-node headers over repeated requests.
- [ ] Confirm data written through the database proxy is visible on multiple Galera nodes.
- [ ] Confirm cache miss followed by cache hit using application logs or trace output.

## 2. Performance tests

### 2.1 Smoke test

Configuration:

- Tool: ApacheBench
- Target: `http://presentation-entry/`
- Requests: 100
- Concurrency: 5

Verified result from `evidence/smoke-test.txt`:

| Metric | Result |
|---|---:|
| Complete requests | 100 |
| Failed requests | 0 |
| Requests per second | 485.78 |
| p50 latency | 9 ms |
| p95 latency | 17 ms |
| p99 latency | 17 ms |
| Maximum latency | 17 ms |

A second smoke run in `evidence/smoke-console.log` recorded 539.72 requests/second and p95 of 13 ms. Both runs had zero failed requests. The difference is normal for short local benchmarks.

### 2.2 Load test

Run from the dashboard using ApacheBench or JMeter. Record the actual output here.

| Metric | Result |
|---|---:|
| Requests | Pending |
| Concurrency | Pending |
| Failed requests | Pending |
| Requests per second | Pending |
| p50 latency | Pending |
| p95 latency | Pending |
| p99 latency | Pending |
| CPU and memory evidence | `evidence/load-docker-stats.txt` |

### 2.3 Stress test

Run concurrency levels 5, 20, 50, 100, and 200. Record actual values only.

| Concurrency | Requests | Failed requests | Throughput | p95 | p99 |
|---:|---:|---:|---:|---:|---:|
| 5 | Pending | Pending | Pending | Pending | Pending |
| 20 | Pending | Pending | Pending | Pending | Pending |
| 50 | Pending | Pending | Pending | Pending | Pending |
| 100 | Pending | Pending | Pending | Pending | Pending |
| 200 | Pending | Pending | Pending | Pending | Pending |

### 2.4 Spike test

Status: Pending.

Recommended configuration: JMeter ramp from 5 to 300 users within 10 seconds, then run for 60 seconds.

Record:

- Maximum error rate.
- Maximum p95 latency.
- Recovery time.
- CPU and memory usage.

### 2.5 Soak test

Status: Pending.

Recommended configuration: moderate load for several hours.

Record:

- Initial and final latency.
- Initial and final memory.
- Total errors.
- Container restarts.
- Connection exhaustion.

### 2.6 Cache effect

Status: Pending.

Procedure:

1. Call `POST /api/cache/clear`.
2. Run the catalog request and record cold-cache latency.
3. Run the same request again and record warm-cache latency.
4. Compare both results.

Cache key:

```text
store:products:cheapest
```

Current TTL:

```text
60 seconds
```

## 3. HA and failover tests

### 3.1 Web node failure

Fault: `web1` was stopped.

Evidence: `evidence/failover-web1.txt`.

Verified result:

| Metric | Result |
|---|---:|
| Requests sent | 20 |
| Successful requests | 18 |
| Failed requests | 2 |
| Availability | 90% |

Interpretation: two requests failed while HAProxy detected and removed the stopped web node. The service recovered and `web1` was started again.


### 3.2 API node failure

Fault: `app1` was stopped.

Evidence: `evidence/failover-app1.txt`.

| Metric | Result |
|---|---:|
| Requests sent | 20 |
| Successful requests | 18 |
| Failed requests | 2 |
| Availability | 90% |

Interpretation: two requests failed while HAProxy detected and removed the stopped API node. The remaining API nodes continued serving requests. `app1` was started again successfully.


### 3.3 Presentation load-balancer failure

Status: Pending.

Run under load:

```powershell
docker compose -f docker-compose.main.yml stop presentation-lb-master
```

Check the backup and Keepalived logs:

```powershell
docker compose -f docker-compose.main.yml logs --tail 100 presentation-keepalived-backup presentation-lb-backup
```

Restore:

```powershell
docker compose -f docker-compose.main.yml start presentation-lb-master
```

Record detection time, outage time, failed requests, and recovery.

### 3.4 Application load-balancer failure

Status: Pending.

Run:

```powershell
docker compose -f docker-compose.main.yml stop application-lb-master
Invoke-WebRequest -UseBasicParsing http://localhost/api/health
docker compose -f docker-compose.main.yml start application-lb-master
```

Record the actual response and recovery result.

### 3.5 Galera secondary-node failure

Fault: `galera2` was stopped.

Evidence files:

- `evidence/failover-galera2-health.txt`
- `evidence/failover-galera2-cluster.txt`

Expected result: Galera remains available with two nodes, and the API remains healthy.

Actual result: `wsrep_cluster_size` was 2 while `galera2` was stopped. The cluster remained `Primary` and the API health endpoint returned HTTP 200.

Recovery: `galera2` was started again and the cluster returned to three synchronized nodes.


### 3.6 Galera former single-point test

Fault: `galera1` was stopped.

Evidence: `evidence/failover-galera1-health.txt`.

Expected result: Applications continue through `database-proxy` and a healthy Galera node.

Actual result: The API health endpoint returned HTTP 200 while `galera1` was stopped.

Recovery: `galera1` was started again and the Galera cluster returned to three synchronized nodes.

### 3.7 Redis failure

Fault: Redis was stopped.

Evidence: `evidence/failover-redis-catalog.txt`.

Actual result: Catalog requests continued while Redis was unavailable.

Recovery: Redis was started again and returned to a healthy state.

Limitation: Redis is currently a single local cache instance. Production should use Redis Sentinel, Redis Cluster, or a managed Redis service.



### 3.8 MongoDB failure

Fault: MongoDB was stopped and then started again.

Evidence:

- MongoDB service status was checked with `docker compose -f docker-compose.main.yml ps mongodb`.
- The container returned to `Up ... (healthy)` status.
- The container exposed port `27017/tcp`.
- The recovery status was captured in the terminal screenshot.

Catalog behavior: Pending execution. Run `GET http://localhost/api/products/cheapest` while MongoDB is stopped and record the actual result.

Reviews behavior: Pending execution. Run `GET http://localhost/api/products/ST-001/reviews` while MongoDB is stopped and record the actual result.

Recovery result: Pass. After MongoDB was started again, the container reported `Up ... (healthy)`.

Limitation: The local Compose project uses one MongoDB instance, not a replica set. Production should use a replica set or a managed MongoDB service.



### 3.9 Entry proxy failure

Status: Pending negative test.

Stopping `presentation-entry` is expected to cause total public outage because it is the single host-published entry point in this local Compose demonstration.

## 4. Chaos engineering tests

### 4.1 Container fault experiment

Target group: `web`

Action: `stop`

Duration: 90 seconds, with a short recovery observation period.

Hypothesis: stopping one web node keeps availability above 99% because two web nodes remain available.

Evidence: Chaos Monkey summary from `/results/chaos-web/summary.json`.

Measured result:

| Metric | Result |
|---|---:|
| Faults injected | 5 |
| Probes sent | 79 |
| Probes failed | 11 |
| Availability | 86.08% |
| Longest outage reported | 1.0 seconds |
| Average successful probe latency | 10.1 ms |

Fault events:

- `web1` stopped and restored four times.
- `web3` stopped and restored once.
- All five restore operations completed successfully.

Conclusion: The recovery mechanism restored every stopped web container, but the measured availability of 86.08% did not meet the hypothesis of at least 99%. The failed probes indicate that the local HAProxy health-check and failover timing caused user-visible interruptions during this experiment. The result should be investigated before claiming production-grade availability.

### 4.2 Network, resource, time, dependency, and compound faults

Status: Not implemented in this lab.

Potential tools: Pumba, Toxiproxy, stress-ng, Chaos Toolkit, or a managed fault-injection service.

## 5. Observability and alerting checks

Status: Partially complete.

Verified:

- Docker resource snapshot: `evidence/baseline-docker-stats.txt`.
- Main service logs: `evidence/application-logs.txt` and Compose logs.
- Nagios is available at `http://localhost:8088/`.

Pending:

- Capture Nagios alerts for each failure test.
- Record mean time to detect.
- Record mean time to recover.
- Add centralized Prometheus/Grafana/OpenTelemetry evidence.

## 6. Backup and restore

Application-only backup and restore was executed locally.

Backup files:

- `backups/store-backup.sql`
- `backups/store-backup-clean.sql`
- `backups/store-backup-portable.sql`

The portable SQL file removed MariaDB executable compatibility comments before restore. The restore command used `--binary-mode=1 --force`.

Verification result:

- `evidence/store-restore-verification.txt`
- `product_count = 12`

The original all-databases dump was not restored because it contained MariaDB system tables and incompatible executable comments. The local backup files must not be committed to GitHub.

## 7. Limitations

- Docker Compose and Keepalived run on one host in this demonstration.
- The published `presentation-entry` port is a single host-level entry point.
- MongoDB is one local instance, not a replica set.
- Redis is one local instance, not Sentinel or Cluster.
- Kubernetes or a managed multi-node platform is required for host-level high availability.
- OpenTelemetry and centralized metrics are not fully implemented.
- TLS, API authentication, and rate limiting are not fully implemented.
