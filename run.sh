#!/bin/sh

# provision NATS user
addgroup sudo
adduser -D -g '' nats
adduser nats sudo
echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# set environment
export SVC=${SVC:-nats}
export EXTRA=${EXTRA:-}
export USER=${USER:-ruser}
export PASS=${PASS:-T0pS3cr3t}
export TLS=${TLS:-false}
export TLSCERT=${TLSCERT:-}
export TLSKEY=${TLSKEY:-}

# run
if [ "$TLS" = false ] ; then
    sudo -E -u nats /gnatsd -m 8222 $EXTRA \
	--user $USER --pass $PASS \
	--cluster nats://0.0.0.0:6222 \
	--routes nats://$USER:$PASS@$SVC:6222
else
    sudo -E -u nats /gnatsd -m 8222 $EXTRA \
        --user $USER --pass $PASS \
	--tls --tlscert $TLSCERT --tlskey $TLSKEY
        --cluster nats://0.0.0.0:6222 \
        --routes nats://$USER:$PASS@$SVC:6222
fi
