#!/bin/sh

log_failure() {
  message="$(date -u '+%Y-%m-%dT%H:%M:%SZ') ERROR [healthcheck] $*"
  printf '%s\n' "$message" >&2
  # Exec probe output is not included in container logs.
  printf '%s\n' "$message" > /proc/1/fd/1
}

if ! response=$(curl -fsS http://localhost:8083/connectors); then
  log_failure "Cannot retrieve connectors from Kafka Connect REST API. Health check failed."
  exit 1
fi
connectors=$(printf '%s' "$response" | grep -Eo '[^]",\[]+')
if [ -z "$connectors" ]; then
  log_failure "No connectors returned by Kafka Connect REST API. Health check failed."
  exit 1
fi

failed=0
for connector in $connectors; do
  if ! status=$(curl -fsS "http://localhost:8083/connectors/$connector/status"); then
    log_failure "Cannot retrieve status for connector '$connector'."
    failed=1
  elif printf '%s' "$status" | grep -q FAILED; then
    log_failure "Connector '$connector' or one of its tasks is FAILED. Status: $status"
    failed=1
  fi
done

if [ "$failed" -ne 0 ]; then
  log_failure "Health check failed. Kubernetes applies the failure threshold and action configured for each probe."
fi
exit "$failed"
