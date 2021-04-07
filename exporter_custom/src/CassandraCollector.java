import io.prometheus.client.Collector;
import io.prometheus.client.CounterMetricFamily;
import io.prometheus.client.GaugeMetricFamily;

import javax.management.*;
import javax.management.remote.JMXConnector;
import javax.management.remote.JMXConnectorFactory;
import javax.management.remote.JMXServiceURL;
import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.net.MalformedURLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

public class CassandraCollector extends Collector {

    @Override
    public List<MetricFamilySamples> collect() {

        System.out.println("Prometheus collects data...");
        List<MetricFamilySamples> mfs = new ArrayList<>();
        List<String> tables = new ArrayList<>();

        HashMap<String, Object>   environment = new HashMap<>();
        String[]  credentials = new String[] {"cassandra", "cassandra"};
        environment.put (JMXConnector.CREDENTIALS, credentials);

        String cassandraNode = System.getenv("CASSANDRA_NODE");
        String portJMX = System.getenv("CASSANDRA_JMX_PORT");

        try (BufferedReader br = new BufferedReader(new FileReader("/log/hosts/seen_hosts.log"))) {
            while (br.ready()) {
                tables.add(br.readLine());
            }
        } catch (IOException e) {
            e.printStackTrace();
        }

        JMXServiceURL url = null;
        try {
            url = new JMXServiceURL("service:jmx:rmi:///jndi/rmi://" + cassandraNode + ":" + portJMX + "/jmxrmi");
        } catch (MalformedURLException e) {
            e.printStackTrace();
        }

        JMXConnector jmxConnector = null;
        try {
            assert url != null;
            jmxConnector = JMXConnectorFactory.connect(url, environment);
        } catch (IOException e) {
            e.printStackTrace();
        }

        MBeanServerConnection mBeanServerConnection = null;
        try {
            assert jmxConnector != null;
            mBeanServerConnection = jmxConnector.getMBeanServerConnection();
        } catch (IOException e) {
            e.printStackTrace();
        }

        for (String table: tables) {
            System.out.println("For table: " + table);

            ObjectName objectName = null;
            try {
                objectName = new ObjectName("org.apache.cassandra.metrics:type=Table,keyspace=ksp,scope=" + table + "_traffic" + ",name=WriteLatency");
            } catch (MalformedObjectNameException e) {
                e.printStackTrace();
            }

            try {
                assert mBeanServerConnection != null;
                long writeRequests = (long) mBeanServerConnection.getAttribute(objectName, "Count");
                mfs.add(new CounterMetricFamily(
                        table + "_writes_total",
                        "Total number of writes to endpoint " + table,
                        writeRequests));
                System.out.println("Added CounterMetricFamily: " + table + "_writes_total: " + writeRequests);
            } catch (MBeanException | IOException | AttributeNotFoundException | InstanceNotFoundException | ReflectionException e) {
                e.printStackTrace();
            }

            try {
                double writeThroughputLastMinute = (double) mBeanServerConnection.getAttribute(objectName, "OneMinuteRate");
                mfs.add(new GaugeMetricFamily(
                        table + "_write_throughput",
                        "Write throughput in last minute to endpoint " + table,
                        writeThroughputLastMinute));
                System.out.println("Added GaugeMetricFamily: " + table + "_write_throughput: " + writeThroughputLastMinute);
            } catch (MBeanException | AttributeNotFoundException | InstanceNotFoundException | ReflectionException | IOException e) {
                e.printStackTrace();
            }
        }

        try {
            jmxConnector.close();
        } catch (IOException e) {
            e.printStackTrace();
        }

        return mfs;
    }

}
