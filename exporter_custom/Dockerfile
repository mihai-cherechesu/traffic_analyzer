FROM openjdk:12-alpine

ARG HOST_CASSA
ARG LISTEN_PORT_CASSA
ARG JMX_PORT_CASSA

ENV CASSANDRA_NODE $HOST_CASSA
ENV CASSANDRA_JMX_PORT $JMX_PORT_CASSA
ENV CASSANDRA_LISTEN_PORT $LISTEN_PORT_CASSA

COPY ./CassandraExporter.jar /cassandra_exporter.jar
COPY ./wait-for /
COPY ./docker-entrypoint.sh /

RUN chmod +x /wait-for /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["java", "-jar", "/cassandra_exporter.jar"]

#COPY ./loop.sh /
#RUN /bin/sh -c 'chmod +x loop.sh'
#CMD ["sh", "/loop.sh"]
