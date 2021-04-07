FROM locona0810/alpine-cqlsh

ARG HOSTNAME
ARG LISTEN_PORT_CASSA

ENV CASSANDRA_NODE $HOSTNAME
ENV CASSANDRA_LISTEN_PORT $LISTEN_PORT_CASSA

COPY cassandra_loader.sh /
COPY wait-for-it.sh /
COPY docker-entrypoint.sh /

# Install tools required for project
RUN apk update && apk add \
    inotify-tools \
    tshark  

RUN chmod +x /wait-for-it.sh /docker-entrypoint.sh /cassandra_loader.sh

ENTRYPOINT ["bash", "/docker-entrypoint.sh"]
CMD ["bash", "/cassandra_loader.sh"]
