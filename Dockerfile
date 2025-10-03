FROM debian:12-slim AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get -yq update \
	&& apt-get -yq upgrade \
	&& apt-get -yq install \
		autoconf \
		automake \
		autopoint \
		bash \
		bison \
		bzip2 \
		flex \
		g++ \
		g++-multilib \
		gettext \
		git \
		gperf \
		intltool \
		libc6-dev-i386 \
		libclang-dev \
		libgdk-pixbuf-xlib-2.0-dev \
		libltdl-dev \
		libgl-dev \
		libpcre2-dev \
		libssl-dev \
		libtool-bin \
		libxml-parser-perl \
		lzip \
		make \
		openssl \
		p7zip-full \
		patch \
		perl \
		python3 \
		python3-mako \
		python3-packaging \
		python3-pkg-resources \
		python3-setuptools \
		python-is-python3 \
		ruby \
		sed \
		sqlite3 \
		unzip \
		wget \
		xz-utils

WORKDIR /opt

RUN git clone --depth=1 https://github.com/mxe/mxe.git

ENV ITEMS="qt6-qtdeclarative qt6-qt5compat qt6-qtimageformats qt6-qtsvg qt6-qttools qt6-qttranslations qt6-qtwebsockets"

RUN cd mxe \
	&& make MXE_TARGETS='x86_64-w64-mingw32.shared' --jobs=4 JOBS=2 $(for i in $ITEMS; do echo -n " download-$i"; done)

RUN cd mxe \
	&& echo "end download and start build base" \
	&& (make MXE_TARGETS='x86_64-w64-mingw32.shared' --jobs=4 JOBS=4 qt6-qtbase || true)

RUN cd mxe \
	&& echo "end build base and start build all" \
	&& make MXE_TARGETS='x86_64-w64-mingw32.shared' --jobs=4 JOBS=4 $ITEMS

RUN cd mxe \
	&& echo "end build base and start build all" \
	&& make MXE_TARGETS='x86_64-w64-mingw32.shared' --jobs=4 JOBS=4 boost curl

RUN cd mxe \
	&& tar -cJf /opt/mxe.tar.xz ./usr ./.ccache

FROM debian:12-slim
COPY --from=builder /opt/mxe.tar.xz /opt/mxe/
COPY --from=builder /usr/bin/xz /usr/bin/xz
RUN apt-get -yq purge perl; \
	rm /usr/bin/perl
