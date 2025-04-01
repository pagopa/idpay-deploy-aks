# idpay-deploy-aks
Container repository for all idpay manifest files.

# How to add a new app

These are the steps needed to add a new app:

- insert a new folder inside the `helm/<env>/<category>` folder (e.g. `helm/dev/top/p4pa-auth`) (for the category it is important to see the confluence page that explains how to choose)
- insert a new file with the same name as the app inside the `helm/_global` folder it does not matter if it is not used
