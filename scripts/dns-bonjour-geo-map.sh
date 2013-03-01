#!/bin/sh

export MAILTO=""
#OLSR Router IPv6 Adresse
ROUTER="2001:470:6c:393::2"
#DNS Master Servername or IPv6 Adresse
#SERVER="127.0.0.1"
SERVER="ns1.pberg.freifunk.net"
#DNS Zonenenname for AAAA entry's
ZONENAME="olsr.pberg.freifunk.net"
ZONENAMEV4="olsr"
#DNS Reverse IPv6 Zone for PTR revnibbles.arpa entry's
ZONENET="2001:470:5038"
#DNS Reverse IPv4 Zone for PTR arpa entry's
ZONENETV4=".olsr.pberg.freifunk.net	#"
#TODO Automate
#uci show olsrd
#olsrd.@LoadPlugin[4].library=olsrd_nameservice.so.0.3
#olsrd.@LoadPlugin[4].hosts_file=/var/etc/hosts.olsr
HOSTS="/var/etc/hosts.olsr.ipv6"
HOSTSV4="/var/etc/hosts.olsr"
LATLON="/var/run/latlon.js.ipv6"
LATLONV4="/var/run/latlon.js"
TTL="240"
#Key file from dnssec-keygen output
KEYFILE="Kpberg.freifunk.net.+157+33698"
IPV6_REGEX='^((([0-9A-Fa-f]{1,4}:){7}[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){6}:[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){5}:([0-9A-Fa-f]{1,4}:)?[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){4}:([0-9A-Fa-f]{1,4}:){0,2}[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){3}:([0-9A-Fa-f]{1,4}:){0,3}[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){2}:([0-9A-Fa-f]{1,4}:){0,4}[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){6}((\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b)\.){3}(\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b))|(([0-9A-Fa-f]{1,4}:){0,5}:((\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b)\.){3}(\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b))|(::([0-9A-Fa-f]{1,4}:){0,5}((\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b)\.){3}(\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b))|([0-9A-Fa-f]{1,4}::([0-9A-Fa-f]{1,4}:){0,5}[0-9A-Fa-f]{1,4})|(::([0-9A-Fa-f]{1,4}:){0,6}[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){1,7}:))(\/(1[0-1][0-9]|12[0-8]|[2-9][0-9]|1[6-9]))?$'
IPV4_REGEX='[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}'
TIME=$(date --rfc-3339=ns)
#COUCHDB="http://couch.pberg.freifunk.net/openwifimap"
COUCHDB="http://map.pberg.freifunk.net/openwifimap"
# via ssh getunnelt ssh -L5984:127.0.0.1:5984 openwrt@couch.pberg.freifunk.net -N &
#COUCHDB="http://127.0.0.1:5984/openwifimap"


update() {
	SERVER="$1"
	ENTRY="$2"
	RECORD="$3"
	NAME="$4"
	DATE="$(date)"
	#echo "update: $ENTRY $RECORD $NAME"
	/usr/bin/nsupdate -v -k "$KEYFILE" <<EOF
server $SERVER
update delete $ENTRY $RECORD
update add $ENTRY $TTL $RECORD $NAME
send
EOF
}

updatesrv() {
	SERVER="$1"
	ENTRY="$2"
	RECORD="$3"
	PORT="$4"
	NAME="$5"
	TXT="$6"
	#echo "updatesrv:  $ENTRY $RECORD $PORT $NAME $TXT"
	/usr/bin/nsupdate -v -k "$KEYFILE" <<EOF
server $SERVER
update delete $ENTRY $RECORD
update delete $ENTRY TXT
update add $ENTRY $TTL TXT "$TXT $DATE"
update add $ENTRY $TTL $RECORD 0 0 $PORT $NAME
send
EOF
}

updateptr() {
	SERVER="$1"
	ENTRY="$2"
	RECORD="$3"
	NAME="$4"
	#echo "updateptr: $ENTRY $RECORD $NAME"
	/usr/bin/nsupdate -v -k "$KEYFILE" <<EOF
server $SERVER
update add $ENTRY $TTL $RECORD $NAME 
send
EOF
}

main() {
	IP6ADDR=""
	IP6ADDR=$(echo "$1" | egrep $IPV6_REGEX)
	IP4ADDR=""
	IP4ADDR=$(echo "$1" | egrep $IPV4_REGEX)
	HOSTNAME="$2"
	LOC="$3"
	TYPE="NONE"
	IPADDR=""
	if [ ! -z "${IP6ADDR}" ] ; then
		TYPE="AAAA"
		IPADDR=$IP6ADDR
	fi
	if [ ! -z "${IP4ADDR}" ] ; then
		TYPE="A"
		IPADDR=$IP4ADDR
	fi
	if [ "$TYPE" == "NONE" ] ; then
		echo "No IP Adresstype found"
		exit 1
	fi
	#eval HOSTNAME=$(echo "$2" | egrep '^([0-9A-Za-z\-\.])*$')
	eval HOSTNAME=$(echo "$HOSTNAME" | sed -e 's/\.olsr.*//')
	if [ ! -z "${HOSTNAME}" ] && [ ! -z "${IPADDR}" ]  && [ ! "${HOSTNAME}" == "localhost" ]; then
		if [ "$TYPE" == "AAAA" ] ; then
			FQDN="$HOSTNAME"."$ZONENAME".
			update "$SERVER" "$FQDN" "$TYPE" "$IPADDR"
			[ -z "${LOC}" ] || update "$SERVER" "$FQDN" "LOC" "$LOC"
			IPADDR=$(ipv6calc --in ipv6addr --out revnibbles.arpa $IPADDR)
			update "$SERVER" "$IPADDR" "PTR" "$FQDN"
			[ -z "${LOC}" ] || update "$SERVER" "$IPADDR" "LOC" "$LOC"
		else
			FQDN="$HOSTNAME"."$ZONENAME".
			update "$SERVER" "$FQDN" "$TYPE" "$IPADDR"
			[ -z "${LOC}" ] || update "$SERVER" "$FQDN" "LOC" "$LOC"
		fi

		HOSTNAME=$(echo "$HOSTNAME" | egrep -v '^.*\..*$')
		if [ ! -z "${HOSTNAME}" ] ; then
			#echo "update $HOSTNAME"
			updateptr "$SERVER" "_ssh._tcp.$ZONENAME". "PTR" "$HOSTNAME._ssh._tcp.$ZONENAME".
			updateptr "$SERVER" "_http._tcp.$ZONENAME". "PTR" "$HOSTNAME._http._tcp.$ZONENAME".
			updatesrv "$SERVER" "$HOSTNAME._ssh._tcp.""$ZONENAME". "SRV" "22" "$HOSTNAME.$ZONENAME". "$HOSTNAME.$ZONENAME".
			updatesrv "$SERVER" "$HOSTNAME._http._tcp.""$ZONENAME". "SRV" "80" "$HOSTNAME.$ZONENAME". "$HOSTNAME.$ZONENAME".
		fi
	else
		echo "No HOSTNAME : $HOSTNAME or no IPADDR : $IPADDR"
	fi
}

#get ipv6 data
router_file=/tmp/router.json
echo "fetch latlon from $ROUTER"
ssh root@$ROUTER "egrep \"^Node|^Self\" $LATLON" | sed -e 's/^Node(//' -e 's/^Self(//' -e 's/);$//' >$router_file

links_file=/tmp/links.json
echo "fetch latlon links from $ROUTER"
ssh root@$ROUTER "egrep \"^PLink\" $LATLON" | sed -e 's/^PLink(//' -e 's/);$//' >$links_file

hosts="/tmp/$ROUTER.hosts"
> "$hosts"
echo "fetch hosts from $ROUTER"
ssh "root@$ROUTER" "cat $HOSTS" | grep "$ZONENET" > "$hosts"

#get ipv4 data
router_filev4=/tmp/routerv4.json
echo "fetch latlonv4 from $ROUTER"
ssh root@$ROUTER "egrep \"^Node|^Self\" $LATLONV4" | sed -e 's/^Node(//' -e 's/^Self(//' -e 's/);$//' >$router_filev4

links_filev4=/tmp/linksv4.json
echo "fetch latlonv4 links from $ROUTER"
ssh root@$ROUTER "egrep \"^PLink\" $LATLONV4" | sed -e 's/^PLink(//' -e 's/);$//' >$links_filev4

hostsv4="/tmp/$ROUTER.hostsv4"
> "$hostsv4"
echo "fetch hostsv4 from $ROUTER"
ssh "root@$ROUTER" "cat $HOSTSV4" | grep "$ZONENETV4" > "$hostsv4"



mkdir -p /tmp/hosts
rm -f /tmp/hosts/*
mkdir -p /tmp/links
rm -f /tmp/links/*
hosts_if=''
cat "$hosts" | while read line ; do
	echo "$line"
	json=''
	host_m=''
	set $line;addr=$1;host=$2
	host_m="$(echo "$host" | sed -e 's/^mid[0-9].//' -e 's/.olsr.*$//')"
	json="$(grep \'"$host_m"\' $router_file)"
	if [ '11'"$json" != '11' ] ; then
		OIFS="$IFS";IFS=","
		set $json;addr1=$1;lat=$2;lon=$3;west=$4;addr2=$5;host1=$6
		IFS=$OIFS
		if ! [ -f /tmp/hosts/$host_m.json ] ; then
			rm -f /tmp/owm.json
			curl -sg --connect-timeout 3 "http://[$addr]/cgi-bin/luci/freifunk/owm.json" > /tmp/owm.json
			if grep -q "$addr" /tmp/owm.json ; then
				mv /tmp/owm.json /tmp/hosts/$host_m.json
			fi
		fi
		if ! [ -f /tmp/hosts/$host_m.json ] ; then
			if [ -f /tmp/hosts/$host_m ] ; then
				echo "},{" >> /tmp/hosts/$host_m
				echo '"name": "'$host'",' >> /tmp/hosts/$host_m
				echo '"ipv6Addresses":["'$addr'"]' >> /tmp/hosts/$host_m
			else
				hosts_if="$hosts_if $host_m"
				echo '"interfaces":[{' > /tmp/hosts/$host_m
				echo '"name": "'$host'",'>> /tmp/hosts/$host_m
				echo '"ipv6Addresses":["'$addr'"]' >> /tmp/hosts/$host_m
			fi
			echo "grep links $addr1 from $links_file"
			egrep "^$addr1" "$links_file" | while read jsonr ; do
				echo "jsonr: $jsonr"
				OIFS="$IFS";IFS=","
				set $jsonr;src=$1;dst=$2;lq=$3;nlq=$4;etx=$5
				IFS=$OIFS
				dst=${dst/\'/}
				dst=${dst/\'/}
				echo "grep $dst $hosts"
				dstjson=$(egrep "^$dst" "$hosts")
				echo $dstjson
				set $dstjson;dstaddr=$1;dsthost=$2
				dsthost_m="$(echo "$dsthost" | sed -e 's/^mid[0-9].//' -e 's/.olsr.*$//')"
				if [ -f /tmp/links/$host_m ] ; then
					echo "},{" >> /tmp/links/$host_m
					echo '"interface": "'$host_m.$ZONENAMEV4'",' >> /tmp/links/$host_m
					echo '"id": "'$dsthost_m'.'$ZONENAMEV4'",' >> /tmp/links/$host_m
					echo '"quality": '$etx >> /tmp/links/$host_m
				else
					hosts_if="$hosts_if $host_m"
					echo '"neighbors":[{' > /tmp/links/$host_m
					echo '"interface": "'$host_m.$ZONENAMEV4'",'>> /tmp/links/$host_m
					echo '"id": "'$dsthost_m'.'$ZONENAMEV4'",' >> /tmp/links/$host_m
					echo '"quality": '$etx >> /tmp/links/$host_m
				fi
			done
		fi
	fi
done


mkdir -p /tmp/hostsv4
rm -f /tmp/hostsv4/*
mkdir -p /tmp/linksv4
rm -f /tmp/linksv4/*
hostsv4_if=''
cat "$hostsv4" 2>/dev/null | while read line ; do
	json=''
	host_m=''
	addr=''
	host=''
	set $line;addr="$1";host="$2"
	host_m="$(echo "$host" | sed -e 's/^mid[0-9].//' -e 's/.olsr.*$//')"
	echo $host_m
	json="$(grep \'"$host_m"\' $router_filev4)"
	if [ '11'"$json" != '11' ] ; then
		echo "$host_m $host"
		OIFS="$IFS";IFS=","
		set $json;addr1=$1;lat=$2;lon=$3;west=$4;addr2=$5;host1=$6
		IFS=$OIFS
		if ! [ -f /tmp/hostsv4/$host_m.json ] ; then
			rm -f /tmp/owm.json
			curl -sg --connect-timeout 3 "http://$addr/cgi-bin/luci/owm.json" > /tmp/owm.json
			if grep -q "$addr" /tmp/owm.json ; then
				mv /tmp/owm.json /tmp/hostsv4/$host_m.json
			fi
		fi
		if ! [ -f /tmp/hostsv4/$host_m.json ] ; then
			if [ -f /tmp/hostsv4/$host_m ] ; then
				echo "},{" >> /tmp/hostsv4/$host_m
				echo '"name": "'$host'",' >> /tmp/hostsv4/$host_m
				echo '"ipv4Addresses":["'$addr'"]' >> /tmp/hostsv4/$host_m
			else
				hostsv4_if="$hostsv4_if $host_m"
				echo '"interfaces":[{' > /tmp/hostsv4/$host_m
				echo '"name": "'"$host"'",'>> /tmp/hostsv4/$host_m
				echo '"ipv4Addresses":["'$addr'"]' >> /tmp/hostsv4/$host_m
			fi
			echo "grep links $addr1 from $links_filev4"
			egrep "^$addr1" "$links_filev4" | while read jsonr ; do
				echo "jsonr: $jsonr"
				OIFS="$IFS";IFS=","
				set $jsonr;src=$1;dst=$2;lq=$3;nlq=$4;etx=$5
				IFS=$OIFS
				dst=${dst/\'/}
				dst=${dst/\'/}
				echo "grep $dst $hosts"
				dstjson=$(egrep "^$dst" "$hostsv4")
				echo $dstjson
				set $dstjson;dstaddr=$1;dsthost=$2
				dsthost_m="$(echo "$dsthost" | sed -e 's/^mid[0-9].//' -e 's/.olsr.*$//')"
				if [ -f /tmp/linksv4/$host_m ] ; then
					echo "},{" >> /tmp/linksv4/$host_m
					echo '"interface": "'$host'",' >> /tmp/linksv4/$host_m
					echo '"id": "'$dsthost_m'.'$ZONENAMEV4'",' >> /tmp/linksv4/$host_m
					echo '"quality": '$etx >> /tmp/linksv4/$host_m
				else
					hosts_if="$hosts_if $host_m"
					echo '"neighbors":[{' > /tmp/linksv4/$host_m
					echo '"interface": "'$host'",'>> /tmp/linksv4/$host_m
					echo '"id": "'$dsthost_m'.'$ZONENAMEV4'",' >> /tmp/linksv4/$host_m
					echo '"quality": '$etx >> /tmp/linksv4/$host_m
				fi
			done
		fi
	fi
done


mkdir -p /tmp/hosts
cd /tmp/hosts/
for i in * ; do
	[ $i == '*' ] && break
	echo "updatev6 $i"
	host=${i/.json/}
	rev=''
	rev=$(curl -4 -sIX HEAD $COUCHDB/$host.$ZONENAMEV4 2>/dev/null | grep ETag | cut -d '"' -f2)
	if [ -f /tmp/hosts/"$host".json ] ; then
		echo "updatev6 server $COUCHDB/$host.$ZONENAMEV4 with luci json"
		if [ -z $rev ] ; then
			curl -4 -sX PUT -H "Content-Type: application/json" "$COUCHDB/$host.$ZONENAMEV4" -T /tmp/hosts/"$host".json
		else
			curl -4 -sX PUT -H "Content-Type: application/json" "$COUCHDB/$host.$ZONENAMEV4?rev=$rev" -T /tmp/hosts/"$host".json
		fi
	else			
		echo "updatev6 server $COUCHDB/$host.$ZONENAMEV4 with bash json begin"
		json="$(grep \'"$host"\' $router_file)"
		OIFS="$IFS";IFS=","
		set $json;addr1=$1;lat=$2;lon=$3;west=$4;addr2=$5;host1=$6
		IFS=$OIFS
		echo "}]" >> /tmp/hosts/"$host"
		echo "}]" >> /tmp/links/"$host"
		ifaces="$(cat /tmp/hosts/"$host")"
		links="$(cat /tmp/links/"$host")"
		echo '{"type": "node", "hostname": "'$host.$ZONENAMEV4'", "longitude": '$lon', "latitude": '$lat', '"$ifaces"',' "$links"'}' > /tmp/hosts/"$host".json
		#if [ -z $rev ] ; then
		#	curl -4 -sX PUT -H "Content-Type: application/json" "$COUCHDB/$host.$ZONENAMEV4" -T /tmp/hosts/"$host".json
		#else
		#	curl -4 -sX PUT -H "Content-Type: application/json" "$COUCHDB/$host.$ZONENAMEV4?rev=$rev" -T /tmp/hosts/"$host".json
		#fi
	fi
done

mkdir -p /tmp/hostsv4
cd /tmp/hostsv4/
for i in * ; do
	[ $i == '*' ] && break
	echo "updatev4 $i"
	host=${i/.json/}
	echo $host
	rev=$(curl -4 -sIX HEAD $COUCHDB/$host.$ZONENAMEV4 2>/dev/null | grep ETag | cut -d '"' -f2)
	echo $rev
	if [ -f /tmp/hostsv4/"$host".json ] ; then
		echo "updatev4 server $COUCHDB/$host.$ZONENAMEV4 with luci json"
		if [ -z $rev ] ; then
			curl -4 -sX PUT -H "Content-Type: application/json" "$COUCHDB/$host.$ZONENAMEV4" -T /tmp/hostsv4/"$host".json
		else
			curl -4 -sX PUT -H "Content-Type: application/json" "$COUCHDB/$host.$ZONENAMEV4?rev=$rev" -T /tmp/hostsv4/"$host".json
		fi
	else
		echo "updatev4 server $COUCHDB/$host.$ZONENAMEV4 with bash json begin"
		json="$(grep \'"$host"\' $router_filev4)"
		OIFS="$IFS";IFS=","
		set $json;addr1=$1;lat=$2;lon=$3;west=$4;addr2=$5;host1=$6
		IFS=$OIFS
		echo "}]" >> /tmp/hostsv4/"$host"
		echo "}]" >> /tmp/linksv4/"$host"
		ifaces="$(cat /tmp/hostsv4/"$host")"
		links="$(cat /tmp/linksv4/"$host")"
		echo '{"type": "node", "hostname": "'$host.$ZONENAMEV4'", "longitude": '$lon', "latitude": '$lat', '"$ifaces"',' "$links"'}' > /tmp/hostsv4/"$host".json
		if [ -z $rev ] ; then
			curl -4 -sX PUT -H "Content-Type: application/json" "$COUCHDB/$host.$ZONENAMEV4" -T /tmp/hostsv4/"$host".json
		else
			curl -4 -sX PUT -H "Content-Type: application/json" "$COUCHDB/$host.$ZONENAMEV4?rev=$rev" -T /tmp/hostsv4/"$host".json
		fi
	fi
done
cd

