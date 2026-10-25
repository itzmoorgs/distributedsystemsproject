FROM debian:bookworm-slim
RUN apt-get update \
    && apt-get install -y --no-install-recommends siege \
    && rm -rf /var/lib/apt/lists/*
COPY run.sh /runbook/run.sh
RUN chmod 0755 /runbook/run.sh
