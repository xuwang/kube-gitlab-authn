include envvars
export

.PHONY: build
build:
	docker build --rm --build-arg repo=${REPO} -t $(IMAGE) .

.PHONY: run
run:
	docker run -it --rm -e GITLAB_API_ENDPOINT=${GITLAB_API_ENDPOINT} -p $(PORT):3000 $(IMAGE)

.PHONY: prune
prune:
	docker container prune
	docker image prune