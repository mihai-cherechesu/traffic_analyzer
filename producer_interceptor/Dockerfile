FROM bash:4.4

ARG HOST_CASSA
ARG LISTEN_PORT_CASSA

ENV CASSANDRA_NODE $HOST_CASSA
ENV CASSANDRA_LISTEN_PORT $LISTEN_PORT_CASSA

COPY interceptor.sh /
COPY producer.sh /
COPY sources /
COPY wrapper_script.sh /
COPY wait-for-it.sh /
COPY docker-entrypoint.sh /

RUN apk add --no-cache tcpdump
RUN /usr/local/bin/bash -c 'chmod +x wrapper_script.sh wait-for-it.sh docker-entrypoint.sh interceptor.sh producer.sh'

ENTRYPOINT ["bash", "/docker-entrypoint.sh"]
CMD ["bash", "/wrapper_script.sh"]
