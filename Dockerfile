FROM debian:trixie AS build
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential autoconf automake libtool pkg-config libcrypto++-dev libcurl4-openssl-dev zlib1g-dev
WORKDIR /src
COPY . .
RUN bash switch_build.sh server && autoreconf -fi && ./configure \
    && make -j2 urbackup_snapshot_helper \
    && cp urbackup_snapshot_helper /urbackup_snapshot_helper

FROM uroni/urbackup-server:2.5.x-zfs@sha256:b4ced89a0de1dbf29b6a4e410f5b3783ce5baa258ac1eb100632a56c9f0d8763
LABEL org.opencontainers.image.source="https://github.com/jftkcs/urbackup_backend_2.5.33_zfspatch"
COPY --from=build /urbackup_snapshot_helper /tmp/urbackup_snapshot_helper
RUN set -eu; \
    dpkg-query -W -f='${Version}' urbackup-server | grep '^2\.5\.38'; \
    helper="$(command -v urbackup_snapshot_helper)"; \
    chown --reference="$helper" /tmp/urbackup_snapshot_helper; \
    chmod --reference="$helper" /tmp/urbackup_snapshot_helper; \
    mv /tmp/urbackup_snapshot_helper "$helper"
