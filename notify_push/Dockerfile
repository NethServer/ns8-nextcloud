# SPDX-License-Identifier: AGPL-3.0-or-later

FROM clux/muslrust:stable AS build
ARG NOTIFY_PUSH_VERSION="1.1.1"

# Download and extract the source code
RUN apt-get update && apt-get install -y wget && \
    wget https://github.com/nextcloud/notify_push/archive/refs/tags/v${NOTIFY_PUSH_VERSION}.tar.gz && \
    tar -xzf v${NOTIFY_PUSH_VERSION}.tar.gz && \
    mv notify_push-${NOTIFY_PUSH_VERSION}/* . && \
    rm -rf notify_push-${NOTIFY_PUSH_VERSION} v${NOTIFY_PUSH_VERSION}.tar.gz

# Build with a dummy main to pre-build dependencies
RUN cp Cargo.toml Cargo.toml.ori
RUN cp -r src/main.rs src/main.rs.ori

RUN mkdir -p src && \
 sed -i '/test_client/d' Cargo.toml && \
 echo "fn main(){}" > src/main.rs && \
 cargo build --release

# Build the real code
RUN mv Cargo.toml.ori Cargo.toml
RUN mv src/main.rs.ori src/main.rs
RUN touch src/main.rs
RUN cargo build --release

# Pick the executable file for the right architecture and system
RUN mv /volume/target/*-unknown-*-musl/release/notify_push /notify_push

FROM scratch

COPY --from=build /notify_push /
EXPOSE 7867

CMD ["/notify_push"]
