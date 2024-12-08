#!/bin/sh

# Force this to start haproxy on first run.
rm /etc/haproxy/haproxy.cfg

while :
do
	echo Looking up t.myanonamouse.net
	host t.myanonamouse.net | grep 'has address' | cut -f 4 -d " " | sort | uniq > /tmp/hostlist
	IPCount=$(wc -l /tmp/hostlist | cut -f 1 -d " ")
	if [ "${IPCount}" -lt 2 ]
	then
		echo Fewer than 2 backends visible, leaving things as they are.
		sleep 1
		continue
	fi

	echo "  Found ${IPCount} live trackers"

	# Now generate the new file.
	echo "Generating haproxy config"
	cat ./basefile > /tmp/new_haproxy.cfg

	ENTRY=0
	while read -r IP
	do
		echo "  Adding ${IP}"
		echo "	server IP${ENTRY} ${IP}:443 check ssl verify none check inter 30s fall 2 rise 2" >> /tmp/new_haproxy.cfg
		ENTRY=$((ENTRY+1))
	done < /tmp/hostlist

	EXISTINGMD5=$(md5sum /etc/haproxy/haproxy.cfg 2>/dev/null| cut -f 1 -d " ")
	NEWMD5=$(md5sum /tmp/new_haproxy.cfg 2>/dev/null| cut -f 1 -d " ")

	if [ "${EXISTINGMD5}" != "${NEWMD5}" ]
	then
		echo "Difference found, rotating configuration"
		mv /tmp/new_haproxy.cfg /etc/haproxy/haproxy.cfg
		/usr/bin/killall haproxy
		/usr/sbin/haproxy -f /etc/haproxy/haproxy.cfg
	else
		echo "No change detected."
	fi

	sleep 60
done
