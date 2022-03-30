ARG GO_VERSION=1.17
ARG XX_VERSION=1.1.0

FROM --platform=$BUILDPLATFORM tonistiigi/xx:${XX_VERSION} AS xx

# Docker buildkit multi-arch build requires golang alpine
FROM --platform=$BUILDPLATFORM golang:${GO_VERSION}-alpine as builder

# Copy the build utilities.
COPY --from=xx / /

ARG TARGETPLATFORM

WORKDIR /workspace

# copy api submodule
COPY api/ api/

# copy modules manifests
COPY go.mod go.mod
COPY go.sum go.sum

# cache modules
RUN go mod download

# copy source code
COPY main.go main.go
COPY controllers/ controllers/
COPY internal/ internal/

# build without specifing the arch
ENV CGO_ENABLED=0
RUN xx-go build -a -o helm-controller main.go

FROM registry.access.redhat.com/ubi8/ubi@sha256:56c374376a42da40f3aec753c4eab029b5ea162d70cb5f0cda24758780c31d81

# link repo to the GitHub Container Registry image
LABEL org.opencontainers.image.source="https://github.com/fluxcd/helm-controller"

ARG TARGETPLATFORM
RUN yum install -y ca-certificates

COPY --from=builder /workspace/helm-controller /usr/local/bin/
COPY LICENSE /licenses/LICENSE

USER 65534:65534

ENTRYPOINT [ "helm-controller" ]
