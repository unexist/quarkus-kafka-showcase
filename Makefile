.DEFAULT_GOAL := jib

clean:
	mvn clean

build: clean
	mvn build

run: clean
	mvn -Pquarkus quarkus:dev

minikube-docker:
	eval $(minikube docker-env)

jib: clean minikube-docker
	mvn -Pquarkus package -Dquarkus.container-image.build=true -Dquarkus.container-image.registry=