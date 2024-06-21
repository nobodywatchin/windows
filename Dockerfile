FROM scratch
COPY --from=qemux/qemu-docker:5.16 / /

ARG VERSION_ARG="0.0"
ARG DEBCONF_NOWARNINGS="yes"
ARG DEBIAN_FRONTEND="noninteractive"
ARG DEBCONF_NONINTERACTIVE_SEEN="true"

# Set the shell with pipefail option
SHELL ["/bin/sh", "-o", "pipefail", "-c"]

# Add testing repository for SPICE and looking glass
RUN echo "deb http://deb.debian.org/debian/ testing main" >> /etc/apt/sources.list.d/sid.list

RUN echo -e "Package: *\nPin: testing n=trixie\nPin-Priority: 350" | tee -a /etc/apt/preferences.d/preferences > /dev/null

RUN set -eu && \
    apt-get update && \
    apt-get --no-install-recommends -y install \
        bc \
        curl \
        7zip \
        wsdd \
        samba \
        xz-utils \
        wimtools \
        dos2unix \
        cabextract \
        genisoimage \
        libxml2-utils \
        git \
        build-essential \
        ninja-build \
        python3-venv \
        libglib2.0-0t64 \
        flex \
        bison \
        qemu-system-modules-spice && \
    apt-get clean && \
    printf "%s\n" "$VERSION_ARG" > /run/version && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Clone and set up the QEMU anti-detection script
RUN git clone https://github.com/zhaodice/qemu-anti-detection.git /opt/qemu-anti-detection && \
    chmod -R 755 /opt/qemu-anti-detection

COPY --chmod=755 ./src /run/
COPY --chmod=755 ./assets /run/assets

ADD --chmod=755 https://raw.githubusercontent.com/christgau/wsdd/v0.8/src/wsdd.py /usr/sbin/wsdd
ADD --chmod=664 https://github.com/qemus/virtiso/releases/download/v0.1.248/virtio-win-0.1.248.tar.xz /drivers.txz

EXPOSE 8006 3389
VOLUME /storage

ENV RAM_SIZE "4G"
ENV CPU_CORES "2"
ENV DISK_SIZE "64G"
ENV VERSION "win11"

ENTRYPOINT ["/usr/bin/tini", "-s", "/run/entry.sh"]
