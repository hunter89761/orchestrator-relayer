# stage 1 Build blobstream binary
FROM --platform=$BUILDPLATFORM docker.io/golang:1.21.5-alpine3.18 as builder

ARG TARGETOS
ARG TARGETARCH

ENV CGO_ENABLED=0
ENV GO111MODULE=on

RUN apk update && apk --no-cache add make gcc musl-dev git bash

COPY . /orchestrator-relayer
WORKDIR /orchestrator-relayer
RUN uname -a &&\
    CGO_ENABLED=${CGO_ENABLED} GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    make build

# final image
FROM docker.io/alpine:3.19.0

ARG USER_NAME=celestia

ENV CELESTIA_HOME=/home/${USER_NAME}

# hadolint ignore=DL3018
RUN apk update && apk add --no-cache \
        bash \
        curl \
        jq

COPY --from=builder /orchestrator-relayer/build/blobstream /bin/blobstream
COPY docker/entrypoint.sh /opt/entrypoint.sh

# p2p port
EXPOSE 30000

ENTRYPOINT [ "/bin/bash", "/opt/entrypoint.sh" ]
