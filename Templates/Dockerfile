FROM nginx:latest

ENV SOMEENV stuffhere

RUN export DEBIAN_FRONTEND noninteractive \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
       ca-certificates \
       curl \
  && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

VOLUME /app
WORKDIR /app

ENTRYPOINT ["/docker-entrypoint.sh"]

