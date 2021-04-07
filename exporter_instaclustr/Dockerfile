FROM openjdk:12-alpine

ARG JMX_SERVICE_URL
ARG LISTEN_PORT_CASSA
ARG JMX_PORT

ENV JMX_SERVICE_URL $JMX_SERVICE_URL
ENV LISTEN_PORT_CASSA $LISTEN_PORT_CASSA
ENV JMX_PORT $JMX_PORT

COPY ./cassandra-exporter-standalone-0.9.10.jar /cassandra_exporter.jar
COPY ./options/opt_file /options/opt_file
COPY ./wait-for /
COPY ./docker-entrypoint.sh /

RUN chmod +x /wait-for /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["java", "-jar", "/cassandra_exporter.jar", "--jmx-user=cassandra", "--jmx-password=cassandra", "--jmx-service-url=service:jmx:rmi:///jndi/rmi://cassandra-node:7199/jmxrmi", "--cql-address=cassandra-node:9042"]  
