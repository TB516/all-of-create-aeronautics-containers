FROM docker.io/library/debian:bookworm-slim

ARG PACK_URL="https://mediafilez.forgecdn.net/files/8005/636/Aoc_Aeronautics_v1.3_serverpack.zip"
ARG PACK_SHA256=""
ARG TEMURIN_JRE_URL="https://api.adoptium.net/v3/binary/latest/21/ga/linux/x64/jre/hotspot/normal/eclipse?project=jdk"

ENV DEBIAN_FRONTEND=noninteractive
ENV JAVA_HOME=/opt/java/openjdk
ENV PATH="${JAVA_HOME}/bin:${PATH}"
WORKDIR /data

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    coreutils \
    curl \
    procps \
    tar \
    unzip \
 && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    mkdir -p "${JAVA_HOME}"; \
    curl -fL --retry 5 --retry-delay 5 -o /tmp/temurin-jre.tar.gz "${TEMURIN_JRE_URL}"; \
    tar -xzf /tmp/temurin-jre.tar.gz --strip-components=1 -C "${JAVA_HOME}"; \
    rm /tmp/temurin-jre.tar.gz; \
    ln -sf "${JAVA_HOME}/bin/java" /usr/local/bin/java; \
    java -version; \
    curl -fL --retry 5 --retry-delay 5 -o /tmp/serverpack.zip "${PACK_URL}"; \
    if [ -n "${PACK_SHA256}" ]; then \
      echo "${PACK_SHA256}  /tmp/serverpack.zip" | sha256sum -c -; \
    fi; \
    mkdir -p /opt/aoc-template; \
    unzip -q /tmp/serverpack.zip -d /opt/aoc-template; \
    rm /tmp/serverpack.zip; \
    chmod +x /opt/aoc-template/start.sh; \
    sed -i \
      -e 's/^JAVA_ARGS=.*/JAVA_ARGS="-Xmx8G -Xms8G"/' \
      -e 's/^WAIT_FOR_USER_INPUT=.*/WAIT_FOR_USER_INPUT=false/' \
      -e 's/^SKIP_JAVA_CHECK=.*/SKIP_JAVA_CHECK=true/' \
      -e 's/^JAVA=.*/JAVA="java"/' \
      -e 's/^SERVERSTARTERJAR_FORCE_FETCH=.*/SERVERSTARTERJAR_FORCE_FETCH=false/' \
      /opt/aoc-template/variables.txt

COPY container-entrypoint.sh /usr/local/bin/container-entrypoint.sh
RUN chmod +x /usr/local/bin/container-entrypoint.sh

EXPOSE 25565/tcp
ENTRYPOINT ["/usr/local/bin/container-entrypoint.sh"]
