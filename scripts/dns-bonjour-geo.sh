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


tempfile=/tmp/router.json
>$tempfile
ssh root@$ROUTER "egrep \"^Node|^Self\" /var/run/latlon.js.ipv6" | sed -e 's/^Node(//' -e 's/);$//' | while read line ; do
	echo $line >> $tempfile
done

ssh root@$ROUTER "cat $HOSTS" | grep "$ZONENET" | while read line ; do
    json=''
    host_m=''
    set $line;addr=$1;host=$2
    host_m="$(echo $host | sed -e 's/^mid[0-9].//' -e 's/.olsr$//')"
    json="$(grep $host_m $tempfile)" 
    if [ 11$json != '11' ] ; then
	OIFS="$IFS";IFS=","
	set $json;addr1=$1;lat=$2;lon=$3;west=$4;addr2=$5;host1=$6
	IFS=$OIFS
	 latdeg="$(echo $lat | cut -d '.' -f1)"
	OIFS="$IFS";IFS="."
	set $lat;latdeg=$1;latval=$2
	IFS=$OIFS
	if [ $latdeg -lt 0 ] ; then
		northsouth= 'S'
	else
		northsouth='N'
	fi
	#TODO replace bc
	#latmin=$(((latval/10000)*6/10))
	#latsec=$(((latval-(latval/10000)*10000)/100*60/100))
	#latsecfrac=$(printf %02d $((latval-(latval/100)*100)))
	latmin=$(echo "($latval*60/1000000)" | bc)
	latmin_=$(echo "scale=5;($latval*60/1000000)" | bc)
	latsec=$(echo "scale=4;(($latmin_ - $latmin)*100000)*60/100000" | bc)

	IFS=$OIFS
	 londeg="$(echo $lon | cut -d '.' -f1)"
	OIFS="$IFS";IFS="."
	set $lon;londeg=$1;lonval=$2
	IFS=$OIFS
	if [ $londeg -lt 0 ] ; then
		eastwest= 'W'
	else
		eastwest='E'
	fi
	#TODO replace bc
	#lonmin=$(((lonval/10000)*6/10))
	#lonsec=$(((lonval-(lonval/10000)*10000)/1000*6))
	#lonsecfrac=$(printf %02d $((lonval-(lonval/100)*100)))
	lonmin=$(echo "($lonval*60/1000000)" | bc)
	lonmin_=$(echo "scale=5;($lonval*60/1000000)" | bc)
	lonsec=$(echo "scale=4;(($lonmin_ - $lonmin)*100000)*60/100000" | bc)

	loc="$latdeg $latmin $latsec $northsouth $londeg $lonmin $lonsec $eastwest"
	loc="$loc 30.00m 1.00m 1.00m 1.00m"
   fi
    main "$addr" "$host" "$loc"
done

