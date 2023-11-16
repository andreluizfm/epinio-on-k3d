deploy-backing-svcs:
	epinio service create postgresql-dev postgres
	epinio service create rabbitmq-dev rabbit
	epinio service create redis-dev redis

deploy-app:
	epinio apps push -v appListeningPort=8000 app/orders.yaml
	epinio apps push -v appListeningPort=8000 app/products.yaml
	epinio apps push -v appListeningPort=8000 app/gateway.yaml
