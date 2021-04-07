# Traffic analyzer

## Tech-stack used:
- Docker 20.10.5, build 55c4c88
- Prometheus version 2.26.0
- Apache Cassandra 3.11.2

## Other tools used:
- inotify-tools 3.14-r2
- docker-compose 1.28.6, build 5db8d86f
- tshark (2.2.15-r0)
- tcpdump
- cassandra-exporter (https://github.com/instaclustr/cassandra-exporter)

## Usage:
Use `git clone` to fetch the source code, then run `sudo docker-compose up -d`.

The `-d` option is ***advised*** due to the high volumes of writes to the stdout, from the loggers.

## Services:
- The *application* service from docker-compose runs a mock traffic producer and an interceptor. The interceptor captures (with tcpdump) the outbound traffic on multiple ports, that can be provided in the *wrapper_script.sh* from the producer_interceptor directory as follows: 

    `./interceptor.sh 80 &` could be changed to `./interceptor.sh 80 81 &`

Also, traffic is captured and stored in *.pcap* files every 10 seconds, which are stored in a bind volume, which will be used by the *cassandra-loader* service.

#### Note:
The interceptor itself captures the inbound traffic by default on the DNS port, 53.

DNS is used in order to capture the *hostname* from the packages and to ease the process of parsing the packets. Reverse DNS cannot be used, as its purpose is to return PTRs instead of the real hostnames we're looking for.

1. The *cassandra-loader* service's job is to parse the .pcap files and load the data into the database. It uses an in-house built dictionary, which is based on a file for lookups (*lookup.txt*), as the associative arrays from bash have unpredictable behaviour in pipelined functions such as `read` (data could vanish from the array, due to the nature of pipes, which creates subshells, local variables can be wiped out). This dictionary is used to map a *destination_ip* to a *hostname*, the latter being extracted from the DNS packages mentioned before.

The data is interpreted from the .pcap files using *tshark*. Further information about the way data is extracted is found in the *cassandra-loader.sh* itself.

Data is inserted to cassandra using the python-based *cqlsh* tool.

2. The *cassandra-node* service is the hosting container of the database. Configurations were needed to allow external communication when metrics are gathered with *JMX*. The authentication is enabled, hence it uses 2 files for configuration *jmxremote.password and jmxremote.access*.

The data model chosen to store the data on the node is simple. As we look at the following query that creates a table:

```
CREATE TABLE <placeholder>(timestamp timestamp, destination_ip text, port smallint, PRIMARY KEY(destination_ip, timestamp)) WITH CLUSTERING ORDER BY (timestamp DESC);
```

The `destination_ip` is the partition key, which would help us scale this database, allowing each partition to store data that refers to it. Timestamp also provides uniqueness and helps us keep the data sorted, for easier reads.

3. The cassandra-exporter-custom is the custom exporter that provides metrics about each individual endpoint. Currently only 2 metrics are provided (write_throughput and writes_total). It is built in java using a simple `Collector` and exposes the metrics at port 9100, with the help of an `HTTPServer`. Each metric is scraped from the database, using a `JMXConnector`.

A *counter* is used for the writes_total metric and a *gauge* for the write_throughput.

Each metric, for each specific endpoint, is prefixed with the name of the endpoint. (e.g. *hahaha_com_writes_total*, *huhuhu_ro_write_throughput*). 

4. The cassandra-exporter-instaclustr is also deployed to provide metrics from our cassandra node. The standalone version is used and it runs with the specific options to specify the *jmx-url*, the *cqlsh-address* (by default it runs on localhost), password and username to authenticate to the cassandra node.

5. Finally, our beloved Prometheus service that scrapes the data from our exporters and displays it really cool, as follows:

(***NOTE***: scrapes are executed at each 60s, hence, our exporters could be seen with the *down* state for a while, until Prometheus reaches them)

### An example of writes-total metrics, for each endpoint.
![](https://i.ibb.co/bWHmvfm/endpoints-writes-total-example.png?)    

### An example of write-throughput metrics, for each endpoint.
![](https://i.ibb.co/mb6HNR0/endpoints-write-throughputs-example.png)


## Service dependencies
All the services mentioned above depend highly on our *cassandra-node* service. Hence, entrypoints had been used in order to execute `wait-for-it.sh` (for bash) and `wait-for` (for sh) to synchornize the containers.