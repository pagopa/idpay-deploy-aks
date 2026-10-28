#!/bin/sh

probe=${1:-healthcheck}

log_failure() {
  message="$(date -u '+%Y-%m-%dT%H:%M:%SZ') ERROR [$probe] $*"
  printf '%s\n' "$message" >&2
  # Exec probe output is not included in container logs.
  printf '%s\n' "$message" > /proc/1/fd/1
}

case "$probe" in
  liveness)
    failure_action="Kubernetes restarts the container when the configured consecutive-failure threshold is reached."
    ;;
  readiness)
    failure_action="The container remains running. Kubernetes keeps it NotReady or marks it NotReady when the configured consecutive-failure threshold is reached."
    ;;
  healthcheck)
    failure_action="Kubernetes applies the failure threshold and action configured for the calling probe."
    ;;
  *)
    log_failure "Invalid probe type '$probe'; expected liveness or readiness."
    exit 1
    ;;
esac

if ! response=$(curl -fsS http://localhost:8083/connectors); then
  log_failure "Cannot retrieve connectors from Kafka Connect REST API. Probe failed. $failure_action"
  exit 1
fi
connectors=$(printf '%s' "$response" | grep -Eo '[^]",\[]+')
if [ -z "$connectors" ]; then
  log_failure "No connectors returned by Kafka Connect REST API. Probe failed. $failure_action"
  exit 1
fi

failed=0
for connector in $connectors; do
  if ! status=$(curl -fsS "http://localhost:8083/connectors/$connector/status"); then
    log_failure "Cannot retrieve status for connector '$connector'."
    failed=1
  elif printf '%s' "$status" | tr -d '\r\n' | grep -Eq '"state"[[:space:]]*:[[:space:]]*"FAILED"'; then
    log_failure "Connector '$connector' or one of its tasks is FAILED. Status: $status"
    failed=1
  fi
done

if [ "$failed" -ne 0 ]; then
  log_failure "Probe failed. $failure_action"
fi
exit "$failed"
