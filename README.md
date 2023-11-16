# Deploy app to Epinio

## Requirements:
- [docker](https://docs.docker.com/engine/install/)
- [epinio cli](https://docs.epinio.io/installation/install_epinio_cli)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [helm](https://helm.sh/docs/intro/install/)
- openjdk-8-jdk
- make

## Create k3d cluster
Start docker service and run `env-setup.sh` to create a k3d cluster with epinio and cert-manager installed.
It will also use sslip.io for dns resolution as required by Epinio. So to access epinio, use the url https://epinio.YOUR_IP_ADDRESS.sslip.io.

After setup is complete and all pods are running, use this command to login to epinio using the cli:
```
epinio login -u admin https://epinio.YOUR_IP_ADDRESS.sslip.io
```
The default password is "password". Enter "y" to trust the certificate.


## Deploy backing services
Deploy 3 necessary services for the application:
```
make deploy-backing-svcs
```

Check if the services are ready:
```
epinio service list

🚢  Listing Services...
Namespace: workspace

✔️  Details:
|   NAME   |            CREATED            | CATALOG SERVICE | VERSION |  STATUS   | APPLICATIONS |
|----------|-------------------------------|-----------------|---------|-----------|--------------|
| postgres | 2023-11-16 17:38:55 -0300 -03 | postgresql-dev  | 15.1.0  | not-ready |              |
| rabbit   | 2023-11-16 17:38:57 -0300 -03 | rabbitmq-dev    | 3.11.5  | not-ready |              |
| redis    | 2023-11-16 17:38:57 -0300 -03 | redis-dev       | 7.0.7   | not-ready |              |
```

After all STATUS changed from **no-ready** to **deployed**, proceed to the next step.

## Deploy app
Get the services credentials and add it to application manifest files. To do so, run the following commands:
```
epinio service show redis
epinio service show postgres
epinio service show rabbit
```

Taking redis for example, you should get this output:
```
🚢  Showing Service...

✔️  Details:
|       KEY       |                                     VALUE                                      |
|-----------------|--------------------------------------------------------------------------------|
| Name            | redis                                                                          |
| Created         | 2023-11-16 17:38:57 -0300 -03                                                  |
| Catalog Service | redis-dev                                                                      |
| Version         | 7.0.7                                                                          |
| Status          | deployed                                                                       |
| Used-By         |                                                                                |
| Internal Routes | x840fc02d524045429941cc15f59e-redis-headless.workspace.svc.cluster.local:6379, |
|                 | x840fc02d524045429941cc15f59e-redis-master.workspace.svc.cluster.local:6379,   |
|                 | x840fc02d524045429941cc15f59e-redis-replicas.workspace.svc.cluster.local:6379  |

⚠️  No settings

✔️  Credentials:
|      KEY       |   VALUE    |
|----------------|------------|
| redis-password | qY3fjN80aV |
```
The redis-password will be different, as it is a random generated value.

Get the values from **redis-password**, **rabbitmq-password** and **postgres-password**.
Update the environment variables **REDIS_PASSWORD**, **RABBIT_PASSWORD** and **DB_PASSWORD** in the apps manifests located at [app](./app)

Deploy the application:
```
make deploy-app
```

## Run tests
Get the gateway address running:
```
kubectl get ingress -n workspace
```

### Smoke
```
./test/nex-smoketest.sh https://gateway.YOUR_IP_ADDRESS.sslip.io
```

### Performance
```
python -m venv ./test/.venv
source ./test/.venv/bin/activate
pip install bzt
./test/nex-bzt.sh https://gateway.YOUR_IP_ADDRESS.sslip.io
```
