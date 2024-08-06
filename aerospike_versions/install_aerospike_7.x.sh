### VERSIONS
VER=7.1.0.0
TOOLS=11.0.0
OS=el8
ARCH=x86_64

### INSTALLS
SERVER_BIN=aerospike-server-enterprise_${VER}_tools-${TOOLS}_${OS}_${ARCH}
LINK=https://download.aerospike.com/artifacts/aerospike-server-enterprise/${VER}/${SERVER_BIN}.tgz
wget -q $LINK
tar -xvf ${SERVER_BIN}.tgz

### PRE-CONFIG STUFF
NS=mydata
sudo mkdir -p /var/log/aerospike/
sudo mkdir -p /etc/aerospike/
ls -l /dev/sda2 | awk '{print $NF}' | while read -r line; do sudo dd if=/dev/zero of=$line bs=1024 count=8192 oflag=direct; done
ID=`ip address | grep 192 | awk {'print $2'} | cut -f1 -d'/' | awk -F "." '{print $4}' | awk '{print substr($0, length($0)-1)}'`
INDEX=A${ID}
IP=`ip address | grep 192 | awk {'print $2'} | cut -f1 -d'/'`
PIP=`ip address | grep 10.0. | awk {'print $2'} | cut -f1 -d'/'`
S1IP=`ip address | grep 192 | awk {'print $2'} | cut -f1 -d'/' | sed 's/\(.*\)\(.\)$/\12/'`
S2IP=`ip address | grep 192 | awk {'print $2'} | cut -f1 -d'/' | sed 's/\(.*\)\(.\)$/\16/'`

### AEROSPIKE CONFIG FILE
cat <<EOF> aerospike.conf
service {
        proto-fd-max 15000

        node-id $INDEX
        cluster-name test-aerocluster.eu
        transaction-max-ms 1500
        log-local-time true
}

logging {
        file /var/log/aerospike/aerospike.log {
                context any info
        }
}
network {
        service {
               address any
               access-address $IP
               alternate-access-address $PIP
               port 3000
       }

       heartbeat {
              mode mesh
              address $IP
              port 3002 # Heartbeat port for this node.
              mesh-seed-address-port $S1IP 3002
              mesh-seed-address-port $S2IP 3002
              interval 150 # controls how often to send a heartbeat packet
              timeout 10 # number of intervals after which a node is considered to be missing
       }

        fabric {
              port 3001
              channel-meta-recv-threads 8
        }

}
security {
        # enable-security true

        log {
                report-authentication true
                report-sys-admin true
                report-user-admin true
                report-violation true
        }
}

namespace mydata {
        # How many copies of the data
        replication-factor 2

        # How full may the memory become before the server begins eviction
        # (expiring records early)
        evict-sys-memory-pct 50

        # How full may the memory become before the server goes read only
        stop-writes-sys-memory-pct 60

        # How long (in seconds) to keep data after it is written Default days,
        # use 0 to never expire/evict.
        default-ttl 0

	# Specify a percentage of record expiration time, read within this interval of the record’s end of life will generate a touch
        # e.g. with default-ttl of 60s, a read with 12 seconds remaining will touch the record. [ 60 x ( 1 - default-read-touch-ttl-pct ) = 12 ]
        default-read-touch-ttl-pct 20

        # The interval at which the main expiration/eviction thread wakes up,
        # to process the namespace.
        nsup-period 120

        # Disables eviction that may occur at cold start for this namespace only
        disable-cold-start-eviction True

	# Data high availability across racks
        rack-id ${ID}

	# SC Mode
        strong-consistency true

        # (optional) write-block is 8MiB in server 7.0 or later so max-record-size can be used to limit the record size.
        max-record-size 128K

#        storage-engine device {
#                device /dev/sda2
#
#                post-write-cache 64
#                read-page-cache true
#
#        	# How full may the disk become before the server begins eviction
#        	# (expiring records early)
#                evict-used-pct 45
#        }
        storage-engine memory {
                file /opt/aerospike/ns1.dat   # Location of a namespace data file on server
                filesize 1G                  # Max size of each file in GiB. Maximum size is 2TiB
                stop-writes-avail-pct 5       # (optional) stop-writes threshold as a percentage of
                                              # devices/files size or data-size.
                stop-writes-used-pct 70       # (optional) stop-writes threshold as a percentage of
                                              # devices/files size, or data-size.
                evict-used-pct 60             # (optional) eviction threshold, as a percentage of
                                              # devices/files size, or data-size.
        }
}
EOF
sudo cp aerospike.conf /etc/aerospike/aerospike.conf

### Log Rotation
cat <<EOF> aerospike.log.rotation
/var/log/aerospike/aerospike.log {
    daily
    rotate 90
    dateext
    compress
    olddir /var/log/aerospike/
    sharedscripts
    postrotate
        /bin/kill -HUP `pgrep -x asd`
    endscript
}
EOF
sudo cp aerospike.log.rotation /etc/logrotate.d/aerospike

#### Feature File License ( DO NOT SHARE THIS FILE )
cat <<EOF> features.conf
# generated 2024-02-23 19:31:59

feature-key-version              2
serial-number                    994482256

account-name                     Aerospike
account-ID                       core-testing

valid-until-date                 2025-01-15

asdb-change-notification         true
asdb-cluster-nodes-limit         0
asdb-compression                 true
asdb-encryption-at-rest          true
asdb-flash-index                 true
asdb-ldap                        true
asdb-pmem                        true
asdb-rack-aware                  true
asdb-secrets                     true
asdb-strong-consistency          true
asdb-vault                       true
asdb-xdr                         true
database-recovery                true
elasticsearch-connector          true
graph-service                    true
mesg-jms-connector               true
mesg-kafka-connector             true
presto-connector                 true
pulsar-connector                 true
spark-connector                  true
vector-service                   true

----- SIGNATURE ------------------------------------------------
MEYCIQDQNHX5yGq0D4As3TKkW5EHiFvOpkdNajEaXISvXdY5WAIhALVIRs4iJKeA
e6qLrSDfUXbVck7EKXmCu07ytGempikcJA==
----- END OF SIGNATURE -----------------------------------------
EOF
sudo cp features.conf /etc/aerospike/features.conf


### INSTALL AEROSPIKE
cd $SERVER_BIN
sudo ./asinstall

sudo systemctl start aerospike


### ACL
HOST=`hostname`
if [[ $HOST = "asd01" ]]; then
  sleep 30
  asadm -Uadmin -Padmin -e "enable; manage acl grant user admin roles read-write"
  asadm -Uadmin -Padmin -e "enable; manage acl grant user admin roles sys-admin"
  asadm -Uadmin -Padmin -e "enable; show user"
fi

if [[ ${HOST} =~ ^asd.* ]]; then
  sleep 30
  asadm -Uadmin -Padmin -e "enable; manage roster stage observed ns ${NS}"
  asadm -Uadmin -Padmin -e "enable; manage recluster"
  asadm -Uadmin -Padmin -e "info"
  asadm -Uadmin -Padmin -e "show pmap"
fi

wget -q https://download.aerospike.com/artifacts/aerospike-prometheus-exporter/1.9.0/aerospike-prometheus-exporter-1.9.0.x86_64.rpm
sudo rpm -Uvh aerospike-prometheus-exporter-1.9.0.x86_64.rpm
sudo sed -i "s/^user = \"\"/user = \"admin\"/g" /etc/aerospike-prometheus-exporter/ape.toml
sudo sed -i "s/^password = \"\"/password = \"admin\"/g" /etc/aerospike-prometheus-exporter/ape.toml
sudo service aerospike-prometheus-exporter start
