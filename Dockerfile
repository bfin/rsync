ARG ALPINE_VERSION=3.8

FROM alpine:${ALPINE_VERSION}

RUN apk --no-cache add rsync
