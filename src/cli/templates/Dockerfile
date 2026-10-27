FROM crystallang/crystal:1.20

ARG WATCHEXEC_VERSION=2.3.2

RUN apt-get update && apt-get install -y curl libsqlite3-dev \
 && WATCHEXEC_ARCH="$(case "$(dpkg --print-architecture)" in amd64) echo x86_64 ;; arm64) echo aarch64 ;; *) exit 1 ;; esac)" \
 && curl -fsSLo watchexec.deb "https://github.com/watchexec/watchexec/releases/download/v${WATCHEXEC_VERSION}/watchexec-${WATCHEXEC_VERSION}-${WATCHEXEC_ARCH}-unknown-linux-gnu.deb" \
 && dpkg -i watchexec.deb \
 && rm watchexec.deb
