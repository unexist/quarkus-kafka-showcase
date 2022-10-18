define JSON_TODO
curl -X 'POST' \
  'http://localhost:8080/todo' \
  -H 'accept: */*' \
  -H 'Content-Type: application/json' \
  -d '{
  "description": "string",
  "done": true,
  "dueDate": {
    "due": "2021-05-07",
    "start": "2021-05-07"
  },
  "title": "string"
}'
endef
export JSON_TODO

# Docker
.PHONY: docker
docker:
	@docker-compose -f docker/docker-compose-avro.yaml \
		-p kafka-avro up

# Podman
PODNAME := avroregistry

pd-machine-init:
	@podman machine init --memory=8192 --cpus=2 --disk-size=20

pd-machine-start:
	@podman machine start

pd-machine-rm:
	@podman machine rm

pd-machine-recreate: pd-machine-rm pd-machine-init pd-machine-start

pd-pod-create:
	@podman pod create -n $(PODNAME) --network bridge \
	-p 8081:8080 -p 9000:9000 -p 9001:9001 -p 9002:9002 -p 9092:9092

pd-pod-rm:
	@podman pod rm -f $(PODNAME)

pd-pod-recreate: pd-pod-rm pd-pod-create

pd-redpanda:
	@podman run -dit --name redpanda --pod=$(PODNAME) vectorized/redpanda

pd-registry-apicurio:
	@podman run -dit --name registry-apicurio --pod=$(PODNAME) \
		-e "QUARKUS_PROFILE=prod" \
		-e "KAFKA_BOOTSTRAP_SERVERS=redpanda:9092" \
		-e "APPLICATION_ID=registry_id" \
		-e "APPLICATION_SERVER=localhost:9000" \
		apicurio/apicurio-registry-mem:2.3.1.Final

pd-registry-karapace:
	@podman run -dit --name registry-karapace --pod=$(PODNAME) \
		--entrypoint='["/bin/sh", "-c", "/bin/bash /opt/karapace/start.sh registry"]' \
		-e "KARAPACE_ADVERTISED_HOSTNAME=karapace-registry" \
		-e "KARAPACE_BOOTSTRAP_URI=redpanda:9092" \
		-e "KARAPACE_PORT=9001" \
		-e "KARAPACE_HOST=0.0.0.0" \
		-e "KARAPACE_CLIENT_ID=karapace" \
		-e "KARAPACE_GROUP_ID=karapace-registry" \
		-e "KARAPACE_MASTER_ELIGIBILITY=true" \
		-e "KARAPACE_TOPIC_NAME=_schemas" \
		-e "KARAPACE_LOG_LEVEL=WARNING" \
		-e "KARAPACE_COMPATIBILITY=FULL" \
		ghcr.io/aiven/karapace:develop

pd-registry-karapace-rest:
	@podman run -dit --name registry-karapace-rest --pod=$(PODNAME) \
		--entrypoint='["/bin/sh", "-c", "/bin/bash /opt/karapace/start.sh rest"]' \
		-e "KARAPACE_PORT=9002" \
		-e "KARAPACE_HOST=0.0.0.0" \
		-e "KARAPACE_ADVERTISED_HOSTNAME=karapace-rest" \
		-e "KARAPACE_BOOTSTRAP_URI=redpanda:9092" \
		-e "KARAPACE_REGISTRY_HOST=karapace-registry" \
		-e "KARAPACE_REGISTRY_PORT=9001" \
		-e "KARAPACE_ADMIN_METADATA_MAX_AGE=0" \
		-e "KARAPACE_LOG_LEVEL=WARNING" \
    	ghcr.io/aiven/karapace:develop

pd-init: pd-machine-init pd-machine-start pd-pod-create

pd-start-apicurio: pd-redpanda pd-registry-apicurio

pd-start-karapace: pd-redpanda pd-registry-karapace pd-registry-karapace-rest

# Tools
todo:
	@echo $$JSON_TODO | bash

list:
	@curl -X 'GET' 'http://localhost:8080/todo' -H 'accept: */*' | jq .

registry-open:
	@open "http://localhost:8081"

kat-listen:
	kafkacat -t todo_created -b localhost:9092 -C -s value=avro -r http://localhost:8081

kat-test:
	kafkacat -t todo_created -b localhost:9092 -P