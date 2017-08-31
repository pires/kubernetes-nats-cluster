#!/bin/sh

# set environment
export SVC=${SVC:-nats}
export EXTRA=${EXTRA:-}
export USER=${USER:-}
export PASS=${PASS:-}
export TLS=${TLS:-false}
export TLSCERT=${TLSCERT:-}
export TLSKEY=${TLSKEY:-}
export TLSCMD=${TLSCMD:-}

# is TLS enabled?
if [ "$TLS" != false ] ; then
    export TLSCMD="--tls --tlscert $TLSCERT --tlskey $TLSKEY"
fi
export TLSCMD=${TLSCMD:-}

# is authentication enabled?
if [ "$USER" != "" ] ; then
    export AUTHCMD="--user $USER --pass $PASS"
    export ROUTESCMD="--routes nats://$USER:$PASS@$SVC:6222"
fi
export AUTHCMD=${AUTHCMD:-}
export ROUTESCMD=${ROUTESCMD:---routes nats://$SVC:6222}

exec /gnatsd \
    -m 8222 \
    --cluster nats://0.0.0.0:6222 \
    --connect_retries 30 \
    $EXTRA \
    $TLSCMD \
    $AUTHCMD \
    $ROUTESCMD
