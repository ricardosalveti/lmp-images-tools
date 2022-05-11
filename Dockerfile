FROM golang:alpine
RUN apk add gcc git glib-dev make musl-dev
RUN git clone https://github.com/foundriesio/ostreeuploader.git /ostreeuploader && \
	cd /ostreeuploader && git checkout ae83a2188808fd6188adb25ac72dffd4beaadd3d 
RUN cd /ostreeuploader && make
RUN go install github.com/GoogleCloudPlatform/docker-credential-gcr@v2.0.5+incompatible

FROM docker:20.10.12-dind
WORKDIR /root/

ENV GARAGE_SIGN_ARCH="cli-0.7.2-48-gf606131.tgz"
ENV GARAGE_SIGN_ARCH_HASH="f20c9f3e08fff277a78786025105298322c54874ca66a753e7ad0b2ffb239502"
RUN wget https://storage.googleapis.com/public-shared-artifacts-fio/mirrors/ota-tuf-cli-releases/${GARAGE_SIGN_ARCH} \
	&& echo "${GARAGE_SIGN_ARCH_HASH}  ${GARAGE_SIGN_ARCH}" | sha256sum -c \
	&& tar -xzf ${GARAGE_SIGN_ARCH} --strip-components=1 -C /usr

RUN apk add --no-cache bash glib libarchive libcurl libsodium nss openjdk8-jre-base python3 py3-pip boost-program_options boost-log boost-filesystem boost-log_setup parted sgdisk git lsblk skopeo ostree docker-compose \
	&& pip3 install expandvars==0.6.5 awscli==1.20.64

RUN wget -O /tmp/docker-app.tgz  https://github.com/docker/app/releases/download/v0.9.0-beta1/docker-app-linux.tar.gz \
	&& tar xf "/tmp/docker-app.tgz" -C /tmp/ \
	&& mkdir -p /usr/lib/docker/cli-plugins \
	&& mv "/tmp/docker-app-plugin-linux" /usr/lib/docker/cli-plugins/docker-app \
	&& rm /tmp/docker*
ENV DOCKER_CLI_EXPERIMENTAL=enabled

COPY --from=0 /ostreeuploader/bin/fiopush /usr/bin/
COPY --from=0 /ostreeuploader/bin/fiocheck /usr/bin/
COPY --from=0 /go/bin/docker-credential-gcr /usr/bin/

CMD bash
ENTRYPOINT []
