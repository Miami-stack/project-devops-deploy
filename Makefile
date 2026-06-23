REGISTRY ?= ghcr.io
GIT_SHA ?= $(shell git rev-parse --short HEAD)
IMAGE_TAG ?= latest
IMAGE_NAME_LATEST ?= $(REGISTRY)/miami-stack/project-devops-deploy:$(IMAGE_TAG)
IMAGE_NAME_SHA ?= $(REGISTRY)/miami-stack/project-devops-deploy:sha-$(GIT_SHA)

docker-build:
	docker build -t $(IMAGE_NAME_LATEST) -t $(IMAGE_NAME_SHA) .

docker-push:
	docker push $(IMAGE_NAME_LATEST)
	docker push $(IMAGE_NAME_SHA)

docker-run:
	docker run --rm -p 8080:8080 -p 9090:9090 \
		-e SPRING_PROFILES_ACTIVE=dev \
		-e JAVA_OPTS="-Xms256m -Xmx512m" \
		$(IMAGE_NAME_LATEST)

test:
	./gradlew test

start: run

run:
	./gradlew bootRun

update-gradle:
	./gradlew wrapper --gradle-version 9.2.1

update-deps:
	./gradlew refreshVersions

install:
	./gradlew dependencies

build:
	./gradlew build

lint:
	./gradlew spotlessCheck

lint-fix:
	./gradlew spotlessApply

.PHONY: build
