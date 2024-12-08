#!/bin/sh

# Force this to start haproxy on first run.
rm ./haproxy.cfg
# rm /etc/haproxy/haproxy.cfg

HOSTS="t.myanonamouse.net tracker.tleechreload.org tracker.torrentleech.org"
PREFIXES="mam tlreload tleech"

while :
do
	# Now generate the new file.
	echo "Generating haproxy config"
	cat ./basefile > ./new_haproxy.cfg
  # printf "\n" >> ./new_haproxy.cfg
	# fontend filter for ${PREFIX}
  for PREFIX in ${PREFIXES}; do
    printf "\t\t\t\t%s\n" "use_backend ${PREFIX} if { path /${PREFIX} }" >> ./new_haproxy.cfg
  done

  # Process each host
  set -- ${PREFIXES}  # Set positional parameters for parallel iteration
  for tracker in ${HOSTS}; do
    PREFIX=$1; shift  # Get corresponding prefix
    echo Looking up "${tracker}"
    host "${tracker}" | grep 'has address' | cut -f 4 -d " " | sort | uniq > ./hostlist
    IPCount=$(wc -l < ./hostlist)
    if [ "${IPCount}" -lt 2 ]
    then
        echo Fewer than 2 backends visible, leaving things as they are.
        sleep 1
        continue
    fi
    echo "  Found ${IPCount} live trackers"
    # Build backend section for ${PREFIX}
    {
      printf "%s\n"         "backend ${PREFIX}"
      printf "\t\t\t\t%s\n" "http-request replace-path /${PREFIX}/(.*) /\2"
      printf "\t\t\t\t%s\n" "mode http"
      printf "\t\t\t\t%s\n" "option http-keep-alive"
      printf "\t\t\t\t%s\n" "option persist"
      printf "\t\t\t\t%s\n" "http-reuse always"
      printf "\t\t\t\t%s\n" "stats enable"
      printf "\t\t\t\t%s\n" "stats uri /stats"
      printf "\t\t\t\t%s\n" "stats refresh 10s"
      printf "\t\t\t\t%s\n" "balance roundrobin"
      printf "\t\t\t\t%s\n" "http-request set-header Host '${tracker}'"
    } >> ./new_haproxy.cfg
    # Add server IPs to backend section
    ENTRY=0
    while read -r IP
    do
      echo "Adding ${IP}"
      printf "\t\t\t\t%s\n" "server IP${ENTRY} ${IP}:443 check ssl verify none check inter 30s fall 2 rise 2" >> ./new_haproxy.cfg
      ENTRY=$((ENTRY+1))
    done < ./hostlist
  done

	# Check if the config has changed
  EXISTINGMD5=$(md5sum /etc/haproxy/haproxy.cfg 2>/dev/null| cut -f 1 -d " ")
	NEWMD5=$(md5sum ./new_haproxy.cfg 2>/dev/null| cut -f 1 -d " ")

	# If the config has changed, reload haproxy
	if [ "${EXISTINGMD5}" != "${NEWMD5}" ]
	then
		echo "Difference found, rotating configuration"
		# mv ./new_haproxy.cfg /etc/haproxy/haproxy.cfg
		# /usr/bin/killall haproxy
		# /usr/sbin/haproxy -f /etc/haproxy/haproxy.cfg
	else
		echo "No change detected."
	fi
	# Wait 60 seconds before checking again
	sleep 60
done
