FROM bash:4.4

ARG HOSTNAME

ENV CASSANDRA_NODE $HOSTNAME

COPY cassandra_loader.sh /

RUN /usr/local/bin/bash -c 'chmod +x cassandra_loader.sh'

# Install tools required for project
RUN apk update && apk add \
    inotify-tools \
    tshark

CMD ["bash", "/cassandra_loader.sh"]
