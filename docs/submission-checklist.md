# Submission checklist

## Required files

- [ ] `docs/architecture.jpg`
- [ ] `README.md`
- [ ] `OPERATIONS.md`
- [ ] `TEST-PLAN.md` with measured results
- [ ] `ToDo.md` with honest status
- [ ] `docker-compose.main.yml`
- [ ] `docker-compose.lab.yml`
- [ ] `env.example`
- [ ] HAProxy and Keepalived configuration files
- [ ] MongoDB, Redis, and Galera configuration files

## Required evidence

- [ ] Docker and Compose versions
- [ ] All services running
- [ ] API health response
- [ ] Galera cluster size equals three
- [ ] MongoDB health response
- [ ] Redis health response
- [ ] Load-test output
- [ ] Web-node failover output
- [ ] API-node failover output
- [ ] Galera-node failover output
- [ ] Chaos Monkey output
- [ ] MariaDB backup and restore output
- [ ] Nagios alert screenshots

## Important limitations to disclose

- Docker Compose runs on one host and does not provide host-level high availability.
- The public `presentation-entry` container is a single entry point.
- MongoDB is a single local instance unless a replica set or managed service is added.
- Redis is a single local instance unless Sentinel, Cluster, or a managed service is added.
- Kubernetes or a managed multi-node platform is the production path.
