ARG DISTRIBUTION

FROM debian:${DISTRIBUTION}-slim

ENV ACTIVATION_CODE="xxxxxxx"
ENV SERVER="smart"
ENV HEALTHCHECK=""
ENV BEARER=""
ENV NETWORK="on"
ENV PROTOCOL="lightway_udp"
ENV CIPHER="chacha20"

ARG NUM
ARG TARGETARCH

COPY expressvpn/ /expressvpn/

RUN apt update && apt install -y --no-install-recommends \
    expect curl ca-certificates iproute2 wget jq iptables iputils-ping

# ExpressVPN Doesn't have arm64, only armhf (32b) or amd64.
# On arm64, install the armhf package

RUN if [ "${TARGETARCH}" = "arm64" ]; then \
    dpkg --add-architecture armhf \
    && apt update && apt install -y --no-install-recommends \
    libc6:armhf libstdc++6:armhf \
    && cd /lib && ln -s arm-linux-gnueabihf/ld-2.23.so ld-linux.so.3; \
    fi

RUN <<EOT sh
    if [ "amd64" = "$TARGETARCH" ]; then
      export EXPRESSVPN_ARCH="amd64"
    else
      export EXPRESSVPN_ARCH="armhf"
    fi
    wget -q "https://www.expressvpn.works/clients/linux/expressvpn_${NUM}-1_${EXPRESSVPN_ARCH}.deb" -O "/expressvpn/expressvpn_${NUM}-1_${EXPRESSVPN_ARCH}.deb"
    dpkg -i "/expressvpn/expressvpn_${NUM}-1_${EXPRESSVPN_ARCH}.deb"
    rm -rf /expressvpn/*.deb
EOT

# RUN if [ "${TARGETARCH}" = "amd64" ]; then \
#       export EXPRESSVPN_ARCH="amd64" ; \
#     else \
#       export EXPRESSVPN_ARCH="armhf" ; \
#     fi \
#     wget -q https://www.expressvpn.works/clients/linux/expressvpn_${NUM}-1_${EXPRESSVPN_ARCH}.deb -O /expressvpn/expressvpn_${NUM}-1_${EXPRESSVPN_ARCH}.deb \
#     && dpkg -i /expressvpn/expressvpn_${NUM}-1_${EXPRESSVPN_ARCH}.deb \
#     && rm -rf /expressvpn/*.deb

RUN apt-get purge --autoremove -y wget \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/log/*.log

HEALTHCHECK --start-period=1m --timeout=10s --interval=10m --retries=3 CMD bash /expressvpn/healthcheck.sh

ENTRYPOINT ["/bin/bash", "/expressvpn/start.sh"]