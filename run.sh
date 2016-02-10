#!/bin/sh

# provision NATS user
addgroup sudo
adduser -D -g '' nats
adduser nats sudo
echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# set environment
export NATS_K8S_SVC=${NATS_K8S_SVC:-nats}
export NATS_EXTRA=${NATS_EXTRA:-}
export NATS_USER=${NATS_USER:-ruser}
export NATS_PASS=${NATS_PASS:-T0pS3cr3t}
export NATS_TLS=${NATS_TLS:-false}

# run
sudo -E -u nats /gnatsd -m 8222 $NATS_EXTRA --user $NATS_USER --pass $NATS_PASS \
    --cluster=nats://0.0.0.0:6222 \
    --routes=nats-route://$NATS_USER:$NATS_PASS@$NATS_K8S_SVC:6222
