#!/bin/sh

export MAILTO=""
#DNS Master Servername or IPv6 Adresse
SERVER="81.169.174.233"
#DNS Zonenenname for AAAA entry's
ZONENAME="pberg.freifunk.net."
#DNS Reverse IPv6 Zone for PTR revnibbles.arpa entry's
ZONENET="2001:470:5038"
TTL="240"
#Key file from dnssec-keygen output
KEYFILE="Kpberg.freifunk.net.+157+33698"
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
update delete $ENTRY $RECORD
send
EOF
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

update "$SERVER" "testing.$ZONENAME" "A" "81.169.174.233"
update "$SERVER" "testing.$ZONENAME" "AAAA" "2a01:238:4324:9700:7412:6a5e:7261:31de"
updateservices "testing" "_ssh._tcp:22 _sftp-ssh._tcp:22 _http._tcp:80"

