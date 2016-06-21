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
export TLSCMD=${TLSCMD:-}

# run
if [ "$TLS" != false ] ; then
    export TLSCMD=${TLSCMD:--tls --tlscert $TLSCERT --tlskey $TLSKEY}
fi

sudo -E -u nats /gnatsd -m 8222 $EXTRA \
    --user $USER --pass $PASS \
    $TLSCMD \
    --cluster nats://0.0.0.0:6222 \
    --routes nats://$USER:$PASS@$SVC:6222
