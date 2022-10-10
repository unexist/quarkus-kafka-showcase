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
      	-p 8081:8080 -p 9092:9092

pd-redpanda:
	@podman run -dit --name redpanda --pod=$(PODNAME) vectorized/redpanda

pd-registry:
	@podman run -dit --name registry --pod=$(PODNAME) \
		-e "QUARKUS_PROFILE=prod" \
		-e "KAFKA_BOOTSTRAP_SERVERS=redpanda:9092" \
		-e "APPLICATION_ID=registry_id" \
		-e "APPLICATION_SERVER=localhost:9000" \
		apicurio/apicurio-registry-mem:2.3.1.Final

pd-init: pd-machine-init pd-machine-start pd-pod-create

pd-start: pd-redpanda pd-registry

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