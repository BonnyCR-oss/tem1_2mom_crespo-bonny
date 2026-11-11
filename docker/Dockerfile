FROM alpine:3.20 AS dependencias
COPY docker/hive/SHA256SUMS /jars/SHA256SUMS
# Descargar las dependencias sin incluir binarios en Git.
RUN set -eu; \
    while read -r checksum archivo; do \
      artifact="${archivo%-0.9.1.jar}"; \
      wget -q "https://repo.maven.apache.org/maven2/org/apache/tez/${artifact}/0.9.1/${archivo}" -O "/jars/${archivo}"; \
    done < /jars/SHA256SUMS; \
    cd /jars; \
    sha256sum -c SHA256SUMS

FROM panovvv/hadoop-hive-spark:2.5.2
USER root
COPY --from=dependencias /jars/*.jar /usr/hive/lib/
COPY docker/entrypoint.sh /opt/examen/entrypoint.sh
COPY docker/hive/sesion.hql /opt/examen/sesion.hql
COPY docker/hive/beeline /usr/hive/bin/beeline
RUN chmod 755 /opt/examen/entrypoint.sh /usr/hive/bin/beeline && chmod 644 /usr/hive/lib/tez-*-0.9.1.jar
