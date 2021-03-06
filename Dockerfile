FROM ubuntu:18.04 as builder

RUN apt-get update && apt-get install -y \
	build-essential \
	bc \
	devscripts \
	xz-utils \
	wget \
	curl \
	ca-certificates \
	bison \
	flex \
	cpio \
	libelf-dev \
	kmod \
	libssl-dev \
	git \
	make

ENV WIREGUARD_VERSION=0.0.20180918
ENV WIREGUARD_URL=https://git.zx2c4.com/WireGuard/snapshot/WireGuard-${WIREGUARD_VERSION}.tar.xz

ADD https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.18.8.tar.xz linux.tar.xz

RUN mkdir /linux && \
	tar --strip-components=1 -xpf linux.tar.xz -C /linux

ADD config /linux/.config

# WireGuard
RUN curl -SsL "${WIREGUARD_URL}" -o /wireguard.tar.xz

RUN mkdir /wireguard && \
	tar --strip-components=1 -xpf wireguard.tar.xz -C /wireguard

WORKDIR /linux

ENV PKGVERSION 1terra

RUN /wireguard/contrib/kernel-tree/create-patch.sh | patch -p1
RUN make -j "$(getconf _NPROCESSORS_ONLN)" KDEB_PKGVERSION=$PKGVERSION INSTALL_MOD_STRIP=1 bindeb-pkg

FROM scratch

COPY --from=builder /linux-headers-4.18.8_1terra_amd64.deb /linux-headers.deb
COPY --from=builder /linux-image-4.18.8_1terra_amd64.deb /linux-image.deb
