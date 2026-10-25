# Distributed system lab: step-by-step operation

## 1. Prerequisites

Install Docker Desktop with Compose, Git, and optionally `ab`, Siege, or JMeter locally. Clone the repository and open a PowerShell terminal in its root.

```powershell
git clone https://github.com/tuxtter/distributedsystems.git
cd distributedsystems
Copy-Item env.example .env
```

Edit `.env` and replace every `change-this-*` value. Do not commit `.env`; it contains credentials.

## 2. Start the three-tier stack

The main stack is `docker-compose.main.yml` in this checkout. Build and start it:

```powershell
docker compose -f docker-compose.main.yml up -d --build --pull always
```

Check startup:

```powershell
docker compose -f docker-compose.main.yml ps
docker compose -f 'docker-compose(1).yml' logs -f app1
```

Open `http://localhost/`, `http://localhost:8088/`, and `http://localhost:8090/` after starting the resilience lab.

## 3. Start the resilience lab

The root `docker-compose.yml` launches the load-test dashboard. It expects the main stack network:

```powershell
docker compose -f docker-compose.lab.yml up -d --build --pull always
```

Open `http://localhost:8090`. Start with the Smoke preset, then Load and Stress. Record throughput, p50, p95, p99, errors, and `docker stats`.

## 4. Verify baseline and data tiers

```powershell
docker compose -f 'docker-compose(1).yml' exec app1 node -e "fetch('http://localhost:8080/health').then(async r => console.log(r.status, await r.text()))"
docker compose -f 'docker-compose(1).yml' exec galera1 mariadb -uroot -p$env:MARIADB_ROOT_PASSWORD -e 'SHOW STATUS LIKE ''wsrep_cluster_size'';'
docker compose -f 'docker-compose(1).yml' exec redis redis-cli -a $env:REDIS_PASSWORD ping
docker compose -f 'docker-compose(1).yml' exec mongodb mongosh --quiet --eval 'db.adminCommand({ping:1})'
```

The application connects to `database-proxy`, not `galera1`. The proxy uses Galera nodes for writes and round-robin reads. Redis is a persistent cache with AOF enabled; MongoDB has a least-privilege application user.

## 5. Failover PoC

Run a load test in the dashboard, then stop one stateless node:

```powershell
docker compose -f 'docker-compose(1).yml' stop web1
docker compose -f 'docker-compose(1).yml' stop app1
docker compose -f 'docker-compose(1).yml' stop galera2
docker compose -f 'docker-compose(1).yml' start web1 app1 galera2
```

Expected result: remaining web and API replicas serve traffic; Galera retains quorum with two nodes; the database proxy removes failed nodes using TCP health checks. Stopping `galera1` is now a valid test because applications use the proxy.

## 6. Chaos Monkey PoC

In the dashboard, run Dry run first. Then select `web`, `app`, or `galera`. For a CLI run:

```powershell
docker compose -f docker-compose.lab.yml exec -e GROUP=web -e ACTION=stop -e DURATION=90 -e INTERVAL=20 -e DOWNTIME=15 lab-chaosmonkey /runbook/run.sh /results/manual-chaos
```

Run load concurrently and compare availability and longest outage with the steady-state hypothesis. The chaos container mounts the Docker socket, so use it only on a trusted local machine.

## 7. MariaDB backup and restore drill

Create a logical backup from the proxy and restore it into a disposable database. Never test restore only on production data.

```powershell
docker compose -f 'docker-compose(1).yml' exec database-proxy sh -c 'apk add --no-cache mariadb-client >/dev/null 2>&1; mariadb-dump -h 127.0.0.1 -P 3306 -u root -p"$MARIADB_ROOT_PASSWORD" --all-databases' > backup.sql
docker compose -f 'docker-compose(1).yml' cp backup.sql galera1:/tmp/backup.sql
docker compose -f 'docker-compose(1).yml' exec galera1 sh -c 'mariadb -uroot -p"$MARIADB_ROOT_PASSWORD" < /tmp/backup.sql'
```

For a real deployment, use scheduled encrypted backups, off-host storage, restore automation, and a documented recovery-time objective.

## 8. Production path

Compose and Keepalived demonstrate the architecture on one Docker host; they do not provide host-level HA. For the final architecture, move web/API replicas to Kubernetes or a managed container platform, use an ingress/load balancer, use a managed MongoDB and Redis or operated replica sets, and keep Galera behind a database-aware endpoint.

The current JPG architecture diagram should show three layers, both HAProxy pairs, Keepalived/VIPs, three web nodes, three API nodes, the database proxy, three Galera nodes, MongoDB, and Redis. Export it from Lucidchart and commit it beside this file.



## MongoDB authentication verification

MongoDB was tested using the root administrator account from the local `.env` file.

The application does not use the MongoDB root account. It uses the `store_app` user.

The `store_app` user has `readWrite` permissions on the `store_reviews` database.

The MongoDB ping returned `{ ok: 1 }`.

