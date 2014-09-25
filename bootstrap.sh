#!/bin/bash

export PATH=$PATH:/usr/local/sbin/
export PATH=$PATH:/usr/sbin/
export PATH=$PATH:/sbin

# Save Enviroemnt Variables incase ot attach to the container with new tty
env | awk '{split($0,a,"\n"); print "export " a[1]}' > /etc/env_profile

cassandra_env="$CASSANDRA_NODE_NAME"_PORT_9160_TCP_ADDR
cassandra_ip=$(printenv $cassandra_env)

sed  -i "/^gora\.cassandrastore\.servers.*/ s/.*//"  $NUTCH_HOME/conf/gora.properties
echo gora.cassandrastore.servers=$cassandra_ip:9160 >> $NUTCH_HOME/conf/gora.properties
vim -c '%s/localhost/'$cassandra_ip'/' -c 'x' $NUTCH_HOME/conf/gora-cassandra-mapping.xml


if [[ $1 == "-d" ]]; then
    while true; do
        sleep 1000;
    done
fi

if [[ $1 == "-bash" ]]; then
    /bin/bash
fi


#iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 9160 -j DNAT --to $cassandra_ip:9160
#iptables -t nat -A PREROUTING -p tcp --dport 9160 -j DNAT --to $cassandra_ip:9160
#iptables -t nat -A POSTROUTING -p tcp -d $cassandra_ip --dport 9160 -j MASQUERADE
#iptables -t nat -A PREROUTING -p tcp --dport 9160 -j DNAT --to $cassandra_ip:9160
#iptables -t nat -A PREROUTING -p tcp --dport 9160 -j DNAT --to-destination 172.17.0.2:9160
