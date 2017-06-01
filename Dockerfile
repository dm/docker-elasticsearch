FROM openjdk:8-jre-alpine

LABEL maintainer "Daniel Macedo <admacedo@gmail.com>"

ENV PATH /usr/share/elasticsearch/bin:$PATH
WORKDIR /usr/share/elasticsearch

# grab su-exec for easy step-down from root
# and bash for "bin/elasticsearch" among others
RUN apk update && \
	apk add --no-cache 'su-exec>=0.2' bash ca-certificates gnupg openssl tar ca-certificates wget; \
	update-ca-certificates; \
	addgroup -S -g 1000 elasticsearch; \
	adduser -S -u 1000 -G elasticsearch -h /usr/share/elasticsearchelasticsearch elasticsearch;

# https://artifacts.elastic.co/GPG-KEY-elasticsearch
ENV GPG_KEY 46095ACC8548582C1A2699A9D27D666CD88E42B4
ENV ELASTICSEARCH_VERSION 5.4.0
ENV ELASTICSEARCH_TARBALL="https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.4.0.tar.gz" \
	ELASTICSEARCH_TARBALL_ASC="https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.4.0.tar.gz.asc" \
	ELASTICSEARCH_TARBALL_SHA1="880b115be755a923f25aea810e3386ccb723cc55"

RUN set -ex; \
	wget -O elasticsearch.tar.gz "$ELASTICSEARCH_TARBALL"; \
	if [ "$ELASTICSEARCH_TARBALL_SHA1" ]; then \
		echo "$ELASTICSEARCH_TARBALL_SHA1 *elasticsearch.tar.gz" | sha1sum -c -; \
	fi; \
	if [ "$ELASTICSEARCH_TARBALL_ASC" ]; then \
		wget -O elasticsearch.tar.gz.asc "$ELASTICSEARCH_TARBALL_ASC"; \
		export GNUPGHOME="$(mktemp -d)"; \
		gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$GPG_KEY"; \
		gpg --batch --verify elasticsearch.tar.gz.asc elasticsearch.tar.gz; \
		rm -rf "$GNUPGHOME" elasticsearch.tar.gz.asc; \
	fi; \
	tar -xf elasticsearch.tar.gz --strip-components=1 && rm elasticsearch.tar.gz; \
	bash -c "mkdir -p ./{plugins,data,logs,config/scripts}/"; \
	bash -c "chown -R elasticsearch:elasticsearch ./{plugins,data,logs,config}/"; \
	\
	export ES_JAVA_OPTS='-Xms32m -Xmx32m'; \
	elasticsearch --version

USER elasticsearch

COPY elasticsearch.yml config/
COPY log4j2.properties config/
COPY bin/es-docker bin/es-docker

USER root
RUN chown -R elasticsearch:elasticsearch config/elasticsearch.yml config/log4j2.properties bin/es-docker && \
	chmod 0750 bin/es-docker

USER elasticsearch
CMD ["/bin/bash", "bin/es-docker"]

EXPOSE 9200 9300
