FROM rust:slim AS build
ARG BINSERVE_VERSION="0.2.0"
ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /usr/src/binserve
ADD https://github.com/mufeedvh/binserve/archive/refs/tags/v${BINSERVE_VERSION}.tar.gz /tmp/
RUN tar -xvf /tmp/v${BINSERVE_VERSION}.tar.gz  --strip-components=1

RUN apt-get update && apt-get install -yf make pkg-config
RUN cargo build --release && \
     install -Dsvm755 ./target/release/binserve ./bin/binserve

FROM gcr.io/distroless/cc:latest AS final
WORKDIR /app
COPY --from=build /usr/src/binserve/bin /bin

ADD 404.html index.html binserve.json /app/

ENTRYPOINT [ "/bin/binserve" ]