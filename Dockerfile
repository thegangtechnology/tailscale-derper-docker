FROM golang:latest AS builder
WORKDIR /app

ARG DERP_VERSION=latest
RUN go install tailscale.com/cmd/derper@${DERP_VERSION} && go install tailscale.com/cmd/derpprobe@${DERP_VERSION}

FROM ubuntu
WORKDIR /app

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends apt-utils && \
    apt-get install -y ca-certificates && \
    mkdir /app/certs

ENV DERP_DOMAIN your-hostname.com
ENV DERP_CERT_MODE letsencrypt
ENV DERP_CERT_DIR /app/certs
ENV DERP_ADDR :443
ENV DERP_STUN true
ENV DERP_STUN_PORT 3478
ENV DERP_HTTP_PORT 80
ENV DERP_VERIFY_CLIENTS false
ENV DERP_VERIFY_CLIENT_URL ""
ENV TAILSCALED_SOCKET_PATH "/var/run/tailscale/tailscaled.sock"

COPY --from=builder /go/bin/derper .
COPY --from=builder /go/bin/derpprobe .

CMD /app/derper --hostname=$DERP_DOMAIN \
    # waiting for this PR to be release https://github.com/tailscale/tailscale/pull/15125. -- Current Version 1.80.3 without PR
    # version 1.82.5 is merge fix so --socket should be usable
    --socket=$TAILSCALED_SOCKET_PATH \
    --certmode=$DERP_CERT_MODE \
    --certdir=$DERP_CERT_DIR \
    --a=$DERP_ADDR \
    --stun=$DERP_STUN  \
    --stun-port=$DERP_STUN_PORT \
    --http-port=$DERP_HTTP_PORT \
    --verify-clients=$DERP_VERIFY_CLIENTS \
    --verify-client-url=$DERP_VERIFY_CLIENT_URL
    

