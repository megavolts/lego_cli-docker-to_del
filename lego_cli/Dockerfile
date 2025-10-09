ARG BUILD_REPOSITORY="megavolts/lego" \
    BUILD_NAME="Lego CLI client" \
    BUILD_DESCRIPTION="CLI client of Let's Encrypt/ACME client and library written in Go" \
    ALPINE_VERSION="latest" \
    BUILD_VERSION

# Stage 1 - install lego as buildplatform

FROM --platform=$BUILDPLATFORM alpine:$ALPINE_VERSION AS buildenv

ARG TARGETARCH \
    BUILD_VERSION

ENV BUILD_VERSION=$BUILD_VERSION

# Set shell
SHELL ["/bin/sh", "-o", "pipefail", "-c"]

RUN apk --update --no-cache add \
        ca-certificates \
        curl \
        file \
        tzdata

RUN echo "Installing lego..." \
    && case "$TARGETARCH" in \
        "linux/amd64") ARCH='linux_amd64' ;; \
        "linux/arm64") ARCH='linux_arm64' ;; \
        "linux/386") ARCH='linux_386' ;; \
        "linux/arm/v7") ARCH='linux_armv7' ;; \
        "linux/arm/v6") ARCH='linux_armv6' ;; \
        *) echo >&2 "[error] unsupported $TARGETARCH architecture"; exit 1 ;; \
    esac \
    &&     LEGO_VERSION=$( echo $BUILD_VERSION | cut -d- -f1 ) \
    && echo $LEGO_VERSION \
    && curl -L "https://github.com/go-acme/lego/releases/download/v${LEGO_VERSION}/lego_v${LEGO_VERSION}_${ARCH}.tar.gz" \
            -o lego.tar.gz \
    && tar -zxf lego.tar.gz -C /usr/local/bin/ lego \
    && chmod +x /usr/local/bin/lego \
    && rm -rf lego.tar.gz

RUN echo "Testing Docker image..." \
    && uname -a \
    && cat /etc/os-release \
    && echo VERSION_NUMBER=$(cat /etc/alpine-release ) \
    && file /usr/local/bin/lego \
    && lego --version \
    && lego --help

COPY rootfs/ /

RUN echo "Configure lego_cli docker image..." \
    && chmod 755 /opt/entrypoint.sh \
    && chmod 755 /opt/lego/renew_certificate.sh

# Stage 2 - build for target platform
FROM  alpine:$ALPINE_VERSION AS lego

ARG BUILD_VERSION \
    BUILD_REPOSITORY \
    BUILD_DESCRIPTION \
    BUILD_VERSION \
    BUILD_NAME \
    BUILD_TITLE 

ENV BUILD_VERSION=${BUILD_VERSION}

# General options
ENV LEGO_EMAIL=
ENV LEGO_DOMAINS=
ENV LEGO_SERVER=
ENV LEGO_CSR=
ENV LEGO_ACCEPT_TOS=true
ENV LEGO_PATH=/opt/ssl/
ENV STAGING=false

# Challenge types
ENV LEGO_HTTP=false

# See Lego DNS providers supported https://go-acme.github.io/lego/dns/#dns-providers
# Defaults https://acme-v02.api.letsencrypt.org/directory
ENV LEGO_DNS=https://acme-v02.api.letsencrypt.org/directory

# Set to true to force renew certificate in LEGO_RENEW_DAYS days [default 30]
ENV LEGO_RENEW=false
ENV LEGO_RENEW_DAYS=30

# Certificate auto-renew feature
ENV CERT_AUTORENEW=false
# Renew the certificate 3 days before expiration
ENV CERT_AUTORENEW_PERIOD=3
# Check certificate expiration once a day by default
ENV CERT_AUTORENEW_CRON_INTERVAL="0 0 * * *"

RUN apk --update --no-cache add \
        ca-certificates \
        tzdata \
    # Clean up local repository of retrieved packages and remove the package lists
    && rm -rf /tmp/* /var/cache/apk/*

COPY --from=buildenv /usr/local/bin/lego /bin/
COPY --from=buildenv /opt /opt

ENTRYPOINT ["/opt/entrypoint.sh"]

CMD ["lego"]

# Metadata
LABEL org.opencontainers.image.vendor="Marc Oggier" \
      org.opencontainers.image.url="https://github.com/${BUILD_REPOSITORY}-docker" \
      org.opencontainers.image.title="$BUILD_NAME" \
      org.opencontainers.image.description="$BUILD_DESCRIPTION" \
      org.opencontainers.image.version="$($BUILD_VERSION | cut -d- -f1)" \
      org.opencontainers.image.documentation="https://github.com/${BUILD_REPOSITORY}-docker"