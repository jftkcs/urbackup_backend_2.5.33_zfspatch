FROM debian:trixie AS build
RUN apt-get update && apt-get install -y --no-install-recommends g++ libc6-dev
WORKDIR /src
COPY . .
RUN g++ -O2 -std=c++11 -DOS_FUNC_NO_NET -DOS_FUNC_NO_IFACE_SERVER -DLINUX \
    snapshot_helper/main.cpp urbackupcommon/os_functions_lin_min.cpp stringtools.cpp \
    -o /urbackup_snapshot_helper

FROM uroni/urbackup-server:2.5.x-zfs@sha256:b4ced89a0de1dbf29b6a4e410f5b3783ce5baa258ac1eb100632a56c9f0d8763
LABEL org.opencontainers.image.source="https://github.com/jftkcs/urbackup_backend_2.5.33_zfspatch"
COPY --from=build /urbackup_snapshot_helper /tmp/urbackup_snapshot_helper
RUN set -eu; \
    dpkg-query -W -f='${Version}' urbackup-server | grep '^2\.5\.38'; \
    helper="$(command -v urbackup_snapshot_helper)"; \
    chown --reference="$helper" /tmp/urbackup_snapshot_helper; \
    chmod --reference="$helper" /tmp/urbackup_snapshot_helper; \
    mv /tmp/urbackup_snapshot_helper "$helper"
