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
 && rm -rf /var/lib/apt/lists/* \
 # 20250419~deb12u2 drops the roots behind the compromised eMudhra intermediates (2026-10-17).
 && dpkg --compare-versions "$(dpkg-query -W -f='${Version}' ca-certificates)" ge '20250419~deb12u2'

RUN set -eux; \
    mkdir -p "${JAVA_HOME}"; \
    curl -fL --retry 5 --retry-delay 5 -o /tmp/temurin-jre.tar.gz "${TEMURIN_JRE_URL}"; \
    tar -xzf /tmp/temurin-jre.tar.gz --strip-components=1 -C "${JAVA_HOME}"; \
    rm /tmp/temurin-jre.tar.gz; \
    ln -sf "${JAVA_HOME}/bin/java" /usr/local/bin/java; \
    java -version; \
    # Temurin has not shipped a cacerts update for the eMudhra intermediate compromise (2026-10-17) yet,
    # so remove the emSign ECC Root CA - G3 root that cross-signs them, then fail the build if either
    # affected root (emSign ECC Root CA - G3, Comodo AAA Certificate Services) is still trusted.
    keytool -delete -cacerts -storepass changeit \
      -alias "cn_emsign_ecc_root_ca__g3,o_emudhra_technologies_limited,ou_emsign_pki,c_in [jdk]" || true; \
    if keytool -list -cacerts -storepass changeit | grep -E \
      '86:A1:EC:BA:08:9C:4A:8D:3B:BE:27:34:C6:12:BA:34:1D:81:3E:04:3C:F9:E8:A8:62:CD:5C:57:A3:6B:BE:6B|D7:A7:A0:FB:5D:7E:27:31:D7:71:E9:48:4E:BC:DE:F7:1D:5F:0C:3E:0A:29:48:78:2B:C8:3E:E0:EA:69:9E:F4'; then \
      exit 1; \
    fi; \
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
