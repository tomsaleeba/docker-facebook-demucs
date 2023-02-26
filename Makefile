SHELL = /bin/sh
current-dir := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

# Default options
gpu = false
mp3output = false
model = htdemucs
splittrack =

.DEFAULT_GOAL := help

.PHONY:
init:
ifeq ($(gpu), true)
  docker-gpu-option = --gpus all
endif
ifeq ($(mp3output), true)
  demucs-mp3-option = --mp3
endif
ifneq ($(splittrack),)
  demucs-twostems-option = --two-stems $(splittrack)
endif

.PHONY:
.SILENT:
help: ## Display available targets
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {sub("\\\\n",sprintf("\n%22c"," "), $$2);printf " \033[36m%-20s\033[0m  %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY:
.SILENT:
run: init build ## Run demucs to split the specified track in the input folder
	docker run --rm -i \
		--name=demucs \
		$(docker-gpu-option) \
		-v $(current-dir)input:/data/input \
		-v $(current-dir)output:/data/output \
		-v $(current-dir)models:/data/models \
		-u $(shell id -u):$(shell id -g) \
		xserrat/facebook-demucs:latest \
		"python3 -m demucs -n $(model) \
			--out /data/output \
			$(demucs-mp3-option) \
			$(demucs-twostems-option) \
			\"/data/input/$(track)\""

.PHONY:
.SILENT:
run-interactive: init build ## Run the docker container interactively to experiment with demucs options
	docker run --rm -it \
		--name=demucs-interactive \
		$(docker-gpu-option) \
		-v $(current-dir)input:/data/input \
		-v $(current-dir)output:/data/output \
		-v $(current-dir)models:/data/models \
		-u $(shell id -u):$(shell id -g) \
		xserrat/facebook-demucs:latest \
		/bin/bash

.PHONY:
.SILENT:
build: ## Build the docker image which supports running demucs with CPU only or with Nvidia CUDA on a supported GPU
	docker build -t xserrat/facebook-demucs:latest .
