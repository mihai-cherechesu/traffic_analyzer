#!/bin/sh

# Note: SYN, ACK (from TCP 3-WH, i.e. SYN, SYN-ACK, SYN) packets are captured too
# and counted as traffic to a specific host. Additionally, received packets from the
# sender require ACKs, which are also counted as traffic.

# A simple filter can be used to count only HTTP requests as traffic to the endpoint,
# but was avoided intentionally.

dns_port="53"
ports=

if [ "$#" -eq 0 ]; then
		echo "[ERROR]: Invalid number of arguments.\nFormat: ./interceptor.sh <port1> [<port2>...<portn>]"
		exit 1
fi

for port in "$@"; do
		if [ $port -ne $dns_port ]; then
				ports="$ports $port or "
		fi
done

ports=${ports%or *}

tcpdump -G 10 '(port'"$ports"'and outbound)' or '(port 53 and inbound)' -w ./log/dump/%Y_%m_%d_%H_%M_%S-dump.pcap
