import io.prometheus.client.exporter.HTTPServer;

public class CassandraExporter {

    static final CassandraCollector collector = new CassandraCollector().register();

    public static void main(String[] args) throws Exception {
        System.out.println("Our custom exporter starts to run...");
        HTTPServer httpServer = new HTTPServer(9100);
    }
}
