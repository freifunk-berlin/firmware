#!/bin/sh           

export MAILTO=""
#OLSR Router IPv6 Adresse
ROUTER="2001:470:6c:393::2"
#DNS Master Servername or IPv6 Adresse
SERVER="127.0.0.1"
#DNS Zonenenname for AAAA entry's
ZONENAME="pberg.freifunk.net."
#DNS Reverse IPv6 Zone for PTR revnibbles.arpa entry's
ZONENET="2001:470:5038"
#TODO Automate
#uci show olsrd
#olsrd.@LoadPlugin[4].library=olsrd_nameservice.so.0.3
#olsrd.@LoadPlugin[4].hosts_file=/var/etc/hosts.olsr
HOSTS="/var/etc/hosts.olsr.ipv6"
TTL="240"
#Key file from dnssec-keygen output
KEYFILE="/etc/named.d/Kpberg.freifunk.net.+157+33698"
IPV6_REGEX='^((([0-9A-Fa-f]{1,4}:){7}[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){6}:[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){5}:([0-9A-Fa-f]{1,4}:)?[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){4}:([0-9A-Fa-f]{1,4}:){0,2}[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){3}:([0-9A-Fa-f]{1,4}:){0,3}[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){2}:([0-9A-Fa-f]{1,4}:){0,4}[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){6}((\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b)\.){3}(\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b))|(([0-9A-Fa-f]{1,4}:){0,5}:((\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b)\.){3}(\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b))|(::([0-9A-Fa-f]{1,4}:){0,5}((\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b)\.){3}(\b((25[0-5])|(1\d{2})|(2[0-4]\d)|(\d{1,2}))\b))|([0-9A-Fa-f]{1,4}::([0-9A-Fa-f]{1,4}:){0,5}[0-9A-Fa-f]{1,4})|(::([0-9A-Fa-f]{1,4}:){0,6}[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){1,7}:))(\/(1[0-1][0-9]|12[0-8]|[2-9][0-9]|1[6-9]))?$'
IPV4_REGEX='[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}'
TIME=$(date --rfc-3339=ns)

update() {
      SERVER="$1"
      ENTRY="$2"
      RECORD="$3"
      NAME="$4"
      DATE="$(date)"
      echo "update: $ENTRY $RECORD $NAME"
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
      echo "updatesrv:  $ENTRY $RECORD $PORT $NAME $TXT"
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
      echo "updateptr: $ENTRY $RECORD $NAME"
      /usr/bin/nsupdate -v -k "$KEYFILE" <<EOF
server $SERVER
update add $ENTRY $TTL $RECORD $NAME 
send
EOF
}

main() {
	echo "$1 : $2 : $3"
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
			FQDN="$HOSTNAME"."$ZONENAME"
			update "$SERVER" "$FQDN" "$TYPE" "$IPADDR"
			[ -z "${LOC}" ] || update "$SERVER" "$FQDN" "LOC" "$LOC"
			IPADDR=$(ipv6calc --in ipv6addr --out revnibbles.arpa $IPADDR)
			update "$SERVER" "$IPADDR" "PTR" "$FQDN"
			[ -z "${LOC}" ] || update "$SERVER" "$IPADDR" "LOC" "$LOC"
		else
			FQDN="$HOSTNAME"."$ZONENAME"
			update "$SERVER" "$FQDN" "$TYPE" "$IPADDR"
			[ -z "${LOC}" ] || update "$SERVER" "$FQDN" "LOC" "$LOC"
		fi

		HOSTNAME=$(echo "$HOSTNAME" | egrep -v '^.*\..*$')
		if [ ! -z "${HOSTNAME}" ] ; then
			echo "update $HOSTNAME"
			updateptr "$SERVER" "_ssh._tcp.$ZONENAME" "PTR" "$HOSTNAME._ssh._tcp.$ZONENAME"
			updateptr "$SERVER" "_http._tcp.$ZONENAME" "PTR" "$HOSTNAME._http._tcp.$ZONENAME"
			updatesrv "$SERVER" "$HOSTNAME._ssh._tcp.""$ZONENAME" "SRV" "22" "$HOSTNAME.$ZONENAME" "$HOSTNAME.$ZONENAME"
			updatesrv "$SERVER" "$HOSTNAME._http._tcp.""$ZONENAME" "SRV" "80" "$HOSTNAME.$ZONENAME" "$HOSTNAME.$ZONENAME"
		fi
	else
		echo "No HOSTNAME : $HOSTNAME or no IPADDR : $IPADDR"
	fi
}


updatens(){
	ns="$1"
	ipv4addr="$2"
	ipv6addr="$3"
	updateptr "$SERVER" "b._dns-sd._udp.$ZONENAME" "PTR" "$ns.$ZONENAME"
	updateptr "$SERVER" "db._dns-sd._udp.$ZONENAME" "PTR" "$ns.$ZONENAME"
	updateptr "$SERVER" "dr._dns-sd._udp.$ZONENAME" "PTR" "$ns.$ZONENAME"
	updateptr "$SERVER" "lb._dns-sd._udp.$ZONENAME" "PTR" "$ns.$ZONENAME"
	updateptr "$SERVER" "r._dns-sd._udp.$ZONENAME" "PTR" "$ns.$ZONENAME"
	updateptr "$SERVER" "_services._dns-sd._udp.$ZONENAME" "PTR" "_ssh._tcp.$ZONENAME"
	updateptr "$SERVER" "_services._dns-sd._udp.$ZONENAME" "PTR" "_sftp-ssh._tcp.$ZONENAME"
	updateptr "$SERVER" "_services._dns-sd._udp.$ZONENAME" "PTR" "_http._tcp.$ZONENAME"
	updateptr "$SERVER" "_services._dns-sd._udp.$ZONENAME" "PTR" "_apple-mobdev._tcp.$ZONENAME"
	updateptr "$SERVER" "_services._dns-sd._udp.$ZONENAME" "PTR" "_atc._tcp.$ZONENAME"
	updateptr "$SERVER" "_services._dns-sd._udp.$ZONENAME" "PTR" "_presence._tcp.$ZONENAME"
	updateptr "$SERVER" "_services._dns-sd._udp.$ZONENAME" "PTR" "_device-info._tcp.$ZONENAME"
	updateptr "$SERVER" "_services._dns-sd._udp.$ZONENAME" "PTR" "_touch-able._tcp.$ZONENAME"
	updateptr "$SERVER" "_services._dns-sd._udp.$ZONENAME" "PTR" "_afpovertcp._tcp.$ZONENAME"
	updateptr "$SERVER" "_services._dns-sd._udp.$ZONENAME" "PTR" "_dacp._tcp.$ZONENAME"
	updateptr "$SERVER" "_services._dns-sd._udp.$ZONENAME" "PTR" "_daap._tcp.$ZONENAME"
	updateptr "$SERVER" "_services._dns-sd._udp.$ZONENAME" "PTR" "_smb._tcp.$ZONENAME"
	updateptr "$SERVER" "_services._dns-sd._udp.$ZONENAME" "PTR" "_workstation._tcp.$ZONENAME"
	updateptr "$SERVER" "_services._dns-sd._udp.$ZONENAME" "PTR" "_jabber._tcp.$ZONENAME"
	updateptr "$SERVER" "_services._dns-sd._udp.$ZONENAME" "PTR" "_xmpp-server._tcp.$ZONENAME"
	updateptr "$SERVER" "_services._dns-sd._udp.$ZONENAME" "PTR" "_xmpp-client._tcp.$ZONENAME"
	updateptr "$SERVER" "_services._dns-sd._udp.$ZONENAME" "PTR" "_dns-update._udp.$ZONENAME"
	updatesrv "$SERVER" "_dns-update._udp.$ZONENAME" "SRV" "53" "$ns.$ZONENAME" "dns update"
	[ -z $ipv4addr ] || update "$SERVER" "$ns.$ZONENAME" "A" "$ipv4addr"
	[ -z $ipv6addr ] || update "$SERVER" "$ns.$ZONENAME" "AAAA" "$ipv6addr"
}
updateservices(){
	name="$1"
	services="$2"
	for i in $services ; do
		OIFS=$IFS;IFS=:
		set $i;srv=$1;port=$2
		IFS=$OIFS
		updateptr "$SERVER" "$srv.$ZONENAME" "PTR" "$name.$srv.$ZONENAME"
		updatesrv "$SERVER" "$name.$srv.$ZONENAME" "SRV" "$port" "$name.$ZONENAME" "$name"
	done
}

updatens "ns1" "81.169.174.233" "2a01:238:4324:9700:7412:6a5e:7261:31de"
updateservices "ns1" "_ssh._tcp:22 _sftp-ssh._tcp:22 _http._tcp:80"

#update "$SERVER" "www.$ZONENAME" "A" "217.197.91.152"
update "$SERVER" "members.$ZONENAME" "A" "81.169.174.233"
update "$SERVER" "members.$ZONENAME" "AAAA" "2a01:238:4324:9700:7412:6a5e:7261:31de"
updateservices "www" "_ssh._tcp:22 _sftp-ssh._tcp:22 _http._tcp:80"

#update "$SERVER" "jabber.$ZONENAME" "A" "217.197.91.152"
update "$SERVER" "jabber.$ZONENAME" "A" "81.169.174.233"
update "$SERVER" "jabber.$ZONENAME" "AAAA" "2a01:238:4324:9700:7412:6a5e:7261:31de"
updateservices "jabber" "_ssh._tcp:22 _sftp-ssh._tcp:22 _http._tcp:80 _jabber._tcp:5269 _xmpp-server._tcp:5269 _xmpp-client._tcp:5222"

#update "$SERVER" "conference.$ZONENAME" "A" "217.197.91.152"
update "$SERVER" "conference.$ZONENAME" "A" "81.169.174.233"
update "$SERVER" "conference.$ZONENAME" "AAAA" "2a01:238:4324:9700:7412:6a5e:7261:31de"
updateservices "conference" "_ssh._tcp:22 _sftp-ssh._tcp:22 _http._tcp:80 _xmpp-server._tcp:5269"

#update "$SERVER" "firmware.pberg.freifunk.net." "A" "217.197.91.152"
update "$SERVER" "firmware.$ZONENAME" "A" "81.169.174.233"
update "$SERVER" "firmware.$ZONENAME" "AAAA" "2a01:238:4324:9700:7412:6a5e:7261:31de"

#update "$SERVER" "git.pberg.freifunk.net." "A" "217.197.91.152"
update "$SERVER" "git.$ZONENAME" "A" "81.169.174.233"
update "$SERVER" "git.$ZONENAME" "AAAA" "2a01:238:4324:9700:7412:6a5e:7261:31de"

update "$SERVER" "imap.$ZONENAME" "A" "217.197.91.152"
update "$SERVER" "imap.$ZONENAME" "AAAA" "2001:470:6c:1ab::2"

update "$SERVER" "smtp.$ZONENAME" "A" "217.197.91.152"
update "$SERVER" "smtp.$ZONENAME" "AAAA" "2001:470:6c:1ab::2"

update "$SERVER" "kifuse02.$ZONENAME" "A" "217.197.91.152"
update "$SERVER" "kifuse02.$ZONENAME" "AAAA" "2001:470:6c:1ab::2"

update "$SERVER" "kifuse03.$ZONENAME" "A" "217.197.91.152"
update "$SERVER" "kifuse03.$ZONENAME" "AAAA" "2001:470:6c:1ab::2"

#update "$SERVER" "ipv6.$ZONENAME" "AAAA" "2001:470:6c:1ab::2"
update "$SERVER" "ipv6.$ZONENAME" "AAAA" "2a01:238:4324:9700:7412:6a5e:7261:31de"


#TODO
HOSTNAME="jabber"
updateptr "$SERVER" "_jabber._tcp.$ZONENAME" "PTR" "_jabber._tcp.$ZONENAME"
updatesrv "$SERVER" "_jabber._tcp.$ZONENAME" "SRV" "5269" "$HOSTNAME.$ZONENAME" "$HOSTNAME.$ZONENAME"
updateptr "$SERVER" "_xmpp-server._tcp.$ZONENAME" "PTR" "_xmpp-server._tcp.$ZONENAME"
updatesrv "$SERVER" "_xmpp-server._tcp.$ZONENAME" "SRV" "5269" "$HOSTNAME.$ZONENAME" "$HOSTNAME.$ZONENAME"
updateptr "$SERVER" "_xmpp-client._tcp.$ZONENAME" "PTR" "_xmpp-client._tcp.$ZONENAME"
updatesrv "$SERVER" "_xmpp-client._tcp.$ZONENAME" "SRV" "5222" "$HOSTNAME.$ZONENAME" "$HOSTNAME.$ZONENAME"

