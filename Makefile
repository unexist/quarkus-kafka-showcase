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

# Tools
todo:
	@echo $$JSON_TODO | bash

list:
	@curl -X 'GET' 'http://localhost:8080/todo' -H 'accept: */*' | jq .

open:
	@open "http://localhost:8081"

kat-listen:
	kafkacat -t todo_created -b localhost:9092 -C -s value=avro -r http://localhost:8081

kat-test:
	kafkacat -t todo_created -b localhost:9092 -P