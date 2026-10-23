# idpay-deploy-aks
Container repository for all idpay manifest files.

The shared Kafka Connect liveness and readiness script is maintained in `scripts/idpay-kafka-connect/healthcheck.sh`.
This directory is a shared Helm dependency of the dev, uat and prod Kafka Connect charts:
it creates the ConfigMap mounted read-only at `/scripts/healthcheck.sh` in the container.
Both probes run the same script with `sh`, so executable permissions are not required.
Each probe passes its name (`liveness` or `readiness`) to identify failure logs and describe the corresponding Kubernetes action.
The script checks REST API availability and connector/task failures; each probe keeps its own timing and failure threshold.

# How to add a new app

These are the steps needed to add a new app:

- insert a new folder inside the `helm/<env>/<category>` folder (e.g. `helm/dev/top/p4pa-auth`) (for the category it is important to see the confluence page that explains how to choose)
- insert a new file with the same name as the app inside the `helm/_global` folder it does not matter if it is not used
