#!/bin/bash

# Filters that capture any TCP/UDP traffic.
# DNS IPv4 (A type) answers are also captured and IPv6 (AAAA type) are intentionally avoided. 

# Example of output:

# 1) UDP metadata (DNS response)
# YYYY-MM-DD | HH:mm:ss.nnnnnn | <proto_udp> | <dest_ip>      | <local_port>,<remote_port> | <hostname_ip>  | <hostname>  | <dns_rcode_flag (1-9)> 
# 2021-04-01 | 20:12:28.435441 | 17          | 172.21.44.14   | 53          ,41237         | 185.107.56.195 | tomsdog.com | 1

# 2) TCP metadata
# YYYY-MM-DD | HH:mm:ss.nnnnnn | <proto_tcp> | <dest_ip>      | <local_port>,<remote_port> |
# 2021-04-01 | 20:12:28.435441 | 6           | 138.68.199.111 | 60204       ,80            |

# Note: Any other TCP, UPD traffic is captured, no matter the protocol that runs on top of them, 
# but is out of the scope of this application.

declare -A ip_to_host

proto_tcp=6
proto_udp=17

dns_type_ipv4=1
dns_resp_succ=0
dns_type_ipv6=28

filters="(dns.qry.type == $dns_type_ipv4 && dns.flags.rcode == $dns_resp_succ) || \
    ip.proto == $proto_tcp || (ip.proto == $proto_udp && dns.qry.type != $dns_type_ipv6)"

cassandra_table_common="_traffic"
cassandra_keyspace="ksp"
cassandra_destination_ip_col="destination_ip"
cassandra_timestamp_col="timestamp"
cassandra_port_col="port"

cassandra_user=cassandra 
cassandra_pass=cassandra
cassandra_ip=$(echo $CASSANDRA_NODE)

cqlsh_call="cqlsh -u $cassandra_user -p $cassandra_pass $cassandra_ip"

echo "[INIT]: Loader starting..."

inotifywait -m -e close_write --format '%w%f' /log/dump/ | while read DUMPFILE
do
		dump_size=$(wc -c $DUMPFILE | cut -d " " -f1)
        echo "Cap file with size: $dump_size"

		if [[ $dump_size -eq 0 ]]; then
				echo "[REMOVED]: ${DUMPFILE}, no packets captured."
				rm -f $DUMPFILE
		else
				echo "[CREATED]: ${DUMPFILE}, size: $dump_size."

				tshark -r ${DUMPFILE} -t ad -Y "$filters" -T fields -E separator=' ' \
				    -e _ws.col.Time \
				    -e ip.proto \
				    -e ip.dst \
				    -e tcp.port \
				    -e udp.port \
				    -e dns.a \
				    -e dns.resp.name \
				    -e dns.flags.rcode | while read -r line; do

						proto=$(echo $line | awk -F ' ' '{print $3}')
						is_dns=$(echo $line | awk -F ' ' '{print $8}')

						if [ $proto -eq $proto_udp ] && [ $is_dns -eq 0 ]; then
								hostname_ip=$(echo $line | awk -F ' ' '{print $6}' | awk -F ',' '{print $1}')
								hostname=$(echo $line | awk -F ' ' '{print $7}' | awk -F ',' '{print $1}' | sed 's/[^a-zA-Z_0-9]/_/g')
								
								if [[ -v "ip_to_host[$hostname_ip]" ]]; then
										echo "Hosted already set in map. No updates on /log/hosts/seen_hosts.log."	
								else
										ip_to_host[$hostname_ip]=$hostname
										echo "$hostname" >> /log/hosts/seen_hosts.log
										
										table_name="$cassandra_keyspace.$hostname$cassandra_table_common"
                                        cassandra_create="CREATE TABLE $table_name(\
                                            $cassandra_timestamp_col timestamp, \
                                            $cassandra_destination_ip_col text, \
                                            $cassandra_port_col smallint, \
                                            PRIMARY KEY($cassandra_destination_ip_col, $cassandra_timestamp_col)) \
                                            WITH CLUSTERING ORDER BY ($cassandra_timestamp_col DESC);"
                                        
                                        echo "Create query: $cassandra_create"
                                        echo "$cassandra_create; exit" | $cqlsh_call
								        echo "Created table!"
								fi
                                
								echo "Loaded into map: ${ip_to_host[$hostname_ip]}"
						else
								timestamp_y_m_d=$(echo $line | awk -F ' ' '{print $1}')
								timestamp_h_m_s_ms=$(echo $line | awk -F ' ' '{print $2}')
								timestamp=$timestamp_t_m_d ${timestamp_h_m_s_ms::-3}
								
								port=$(echo $line | awk -F ' ' '{print $5}' | awk -F ',' '{print $2}')
								destination_ip=$(echo $line | awk -F ' ' '{print $4}')
								
								table_name="$cassandra_keyspace.${ip_to_host[$destination_ip]}$cassandra_table_common"
								cassandra_insert="INSERT INTO $table_name\
								    ($cassandra_destination_ip_col, \
								    $cassandra_timestamp_col, \
								    $cassandra_port_col) \
								    VALUES('$destination_ip', '$timestamp', $port);"
								
								echo "Insert query: $cassandra_insert"
								echo "$cassandra_insert; exit" | $cqlsh_call
								echo "Loaded to Cassandra!"
						fi
				done
				echo "[LOADED]: ${DUMPFILE} successfully loaded into Cassandra and can be safely removed from the filesystem."
		fi			
done
