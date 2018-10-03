# Based on https://github.com/mvanholsteijn/docker-makefile

SHELL = /bin/bash
IMAGE_NAME = 899239495551.dkr.ecr.us-east-2.amazonaws.com/rsync
RELEASE_SUPPORT := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))/.make-release-support
VERSION = $(shell . $(RELEASE_SUPPORT) ; getVersion)
TAG = $(shell . $(RELEASE_SUPPORT); getTag)

.PHONY: build release minor-release major-release tag check-status check-release push

build: .release
	docker build \
		--build-arg ALPINE_VERSION=$(TAG) \
		--tag $(IMAGE_NAME):$(VERSION) \
		.
	docker tag $(IMAGE_NAME):$(VERSION) $(IMAGE_NAME):latest

push: 
	docker push $(IMAGE_NAME):$(VERSION)
	docker push $(IMAGE_NAME):latest

release: check-status check-release build push

snapshot: build push

tag-minor-release: VERSION := $(shell . $(RELEASE_SUPPORT); nextMinorLevel)
tag-minor-release: .release tag 

tag-major-release: VERSION := $(shell . $(RELEASE_SUPPORT); nextMajorLevel)
tag-major-release: .release tag 

minor-release: tag-minor-release release
	@echo $(VERSION)

major-release: tag-major-release release
	@echo $(VERSION)

tag: TAG=$(shell . $(RELEASE_SUPPORT); getTag $(VERSION))
tag: check-status
	@. $(RELEASE_SUPPORT) ; ! tagExists $(TAG) || (echo "ERROR: tag $(TAG) for version $(VERSION) already tagged in git" >&2 && exit 1)
	@. $(RELEASE_SUPPORT) ; setRelease $(VERSION)
	git add .
	git commit -m "Bumped to version $(VERSION)"
	git tag $(TAG)
	@ if [ -n "$(shell git remote -v)" ] ; then git push --follow-tags ; else echo 'No remote to push tags to' ; fi

check-status:
	@. $(RELEASE_SUPPORT) ; ! hasChanges || (echo "ERROR: there are still outstanding changes" >&2 && exit 1)

check-release: .release
	@. $(RELEASE_SUPPORT) ; tagExists $(TAG) || (echo "ERROR: version not yet tagged in git. make [minor,major]-release." >&2 && exit 1)
	@. $(RELEASE_SUPPORT) ; ! differsFromRelease $(TAG) || (echo "ERROR: current directory differs from tagged $(TAG). make [minor,major]-release." ; exit 1)
