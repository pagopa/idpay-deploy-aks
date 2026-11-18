# idpay-deploy-aks
Container repository for all idpay manifest files.

The shared Kafka Connect liveness and readiness script is maintained in `scripts/idpay-kafka-connect/healthcheck.sh`.
This directory is a shared Helm dependency of the dev, uat and prod Kafka Connect charts:
it creates the ConfigMap mounted read-only at `/scripts/healthcheck.sh` in the container.
Both probes run the same script with `sh`, so executable permissions are not required.
Each probe passes its name (`liveness` or `readiness`) to identify failure logs and describe the corresponding Kubernetes action.
The script checks REST API availability and connector/task failures; each probe keeps its own timing and failure threshold.

## Temporary Java mitigation (CVE-2026-114938)

The DEV, UAT, and PROD JVM service values, plus `helm/dev/ext/values.yaml`,
set both `-XX:-UseBASE64Intrinsics` and `-XX:UseAVX=2` in `JAVA_TOOL_OPTIONS`,
preserving existing JVM options. Native Timeline and the isolated Go candidate
are excluded.

These are alternative workarounds; both are configured here as requested for
amd64 deployments. Disabling Base64 intrinsics targets the vulnerable decoder;
limiting AVX to AVX2 also disables unrelated AVX-512 optimizations. Performance
may decrease. Do not reuse these settings on ARM64, where `UseAVX` can prevent
JVM startup.

Before rollout, confirm both options are supported by each image's actual JVM
vendor/build. Native executables do not consume `JAVA_TOOL_OPTIONS` as JVM
startup options. After restarting every JVM instance, query its live process
with `jcmd <pid> VM.flags -all` and confirm `UseBASE64Intrinsics = false` and
`UseAVX = 2`. The manifests alone do not establish exposure or running protection.

These flags do not replace a patched JVM. Rebuild and redeploy images using a
vendor-confirmed fixed runtime, then remove the workarounds after verification.
See the [vendor advisory](https://access.redhat.com/security/vulnerabilities/RHSB-2026-018).

The DEV resources for onboarding-workflow, wallet, payment-instrument, ranker,
and Timeline match their last healthy live revision. The mitigation rollout
reapplied lower repository resource settings: Timeline was OOM-killed at a
64Mi memory limit, while the four JVM services hit liveness restarts during
startup at a 200m CPU limit. They retain the JVM mitigations with a 600m CPU
and 1024Mi memory limit; native Timeline uses a 200m CPU and 200Mi memory limit.
Before rollout, compare resource settings with the live revision as well as
checking JVM option compatibility.

# How to add a new app

These are the steps needed to add a new app:

- insert a new folder inside the `helm/<env>/<category>` folder (e.g. `helm/dev/top/p4pa-auth`) (for the category it is important to see the confluence page that explains how to choose)
- insert a new file with the same name as the app inside the `helm/_global` folder it does not matter if it is not used
