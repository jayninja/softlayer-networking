#!/bin/bash
#
# This is sloppy as hell. But it fit what I needed at the time. Feel free to contribute. 
# - James

CONFIGDRIVE=`blkid -t TYPE="vfat" | cut -f1 -d':'`
MOUNTPOINT="/slconfig"
JQBIN="/bin/tmpjq"
if [ -e  /tmp/routes.sh ]
then
  rm -f /tmp/routes.sh
fi

echo "ConfigDrive found at $CONFIGDRIVE"
mkdir -pv $MOUNTPOINT
mount $CONFIGDRIVE $MOUNTPOINT
RET=$?
if [ $RET -ne 0 ]; 
then
  echo "Mounting config drive failed error"
  exit
fi

rm -f /etc/sysconfig/network-scripts/ifcfg-* /etc/sysconfig/network-scripts/route-*

########
function parse_routes {
  NETWORK=$2
  NAME=$3
  NETMASK=`$JQBIN -r ".networks | .[] | select(.link==\"$1\") | .routes | .[] | select(.network==\"$2\") | .netmask" $MOUNTPOINT/openstack/latest/network_data.json`
  GATEWAY=`$JQBIN -r ".networks | .[] | select(.link==\"$1\") | .routes | .[] | select(.network==\"$2\") | .gateway" $MOUNTPOINT/openstack/latest/network_data.json`
  echo "/sbin/route add -net $NETWORK netmask $NETMASK gw $GATEWAY dev $NAME" >> /tmp/routes.sh
}

# set ifcfg files first. Since we need it to add routes. 
for i in `$JQBIN -r '.links | .[].id' $MOUNTPOINT/openstack/latest/network_data.json`
do
  # parse out the info for each ifcfg file
  NAME=`$JQBIN -r ".links | .[] | select(.id==\"$i\") | .name" $MOUNTPOINT/openstack/latest/network_data.json` 
  IP_ADDR=`$JQBIN -r ".networks | .[] | select(.link==\"$i\") | .ip_address" $MOUNTPOINT/openstack/latest/network_data.json`
  NETMASK=`$JQBIN -r ".networks | .[] | select(.link==\"$i\") | .netmask" $MOUNTPOINT/openstack/latest/network_data.json`

  # internal interface has multiple routes :|
  if [ `$JQBIN -r ".networks | .[] | select(.link==\"$i\") | .routes | .[] | .network" $MOUNTPOINT/openstack/latest/network_data.json | wc -l` -gt 1 ];
  then
    echo "INTERFACE HAS MORE THAN ONE ROUTE"

    for x in `$JQBIN -r ".networks | .[] | select(.link==\"$i\") | .routes | .[] | .network" $MOUNTPOINT/openstack/latest/network_data.json`; 
    do
       # i = link ; x = network; NAME = device_name
       parse_routes $i $x $NAME
    done
  else 
    GATEWAY=`$JQBIN -r ".networks | .[] | select(.link==\"$i\") | .routes | .[] | .gateway" $MOUNTPOINT/openstack/latest/network_data.json`
  fi

echo "DEVICE=\"$NAME\"
ONBOOT=\"yes\"
TYPE=\"Ethernet\"
BOOTPROTO=\"none\"
GATEWAY=\"$GATEWAY\"
IPADDR=\"$IP_ADDR\"
NETMASK=\"$NETMASK\"
USERCTL=\"no\"
PEERDNS=\"yes\"
IPV6INIT=\"no\"
" > /etc/sysconfig/network-scripts/ifcfg-$NAME

done

# bringing up the interfaces so we can add routes
/etc/init.d/network restart
bash -x /tmp/routes.sh

# now that our interfaces are up, and our routes are in place... we still need to make the routes perm.
for NAME in `$JQBIN -r '.links | .[].name' $MOUNTPOINT/openstack/latest/network_data.json`
do
  /sbin/ip route | grep $NAME > /etc/sysconfig/network-scripts/route-$NAME
done

umount $MOUNTPOINT
