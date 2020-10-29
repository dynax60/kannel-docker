IMAGE_NAME ?= dynax60/kannel
IMAGE_VERSION ?= r5302
IMAGE=$(IMAGE_NAME):$(IMAGE_VERSION)

.PHONY: build release

build: Dockerfile
	docker build -t $(IMAGE) .

push: 
	docker push $(IMAGE)

release: build
	make push -e IMAGE_VERSION=$(IMAGE_VERSION)

default: build
