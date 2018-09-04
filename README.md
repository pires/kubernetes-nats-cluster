# kubernetes-nats-cluster
NATS cluster on top of Kubernetes made easy.

**THIS PROJECT HAS BEEN ARCHIVED. SEE https://github.com/nats-io/nats-operator**

**NOTE:** This repository provides a configurable way to deploy secure, available
and scalable NATS clusters. However, [a _smarter_ solution](https://github.com/pires/nats-operator)
in on the way (see [#5](https://github.com/pires/kubernetes-nats-cluster/issues/5)).

## Pre-requisites

* Kubernetes cluster v1.8+ - tested with v1.9.0 on top of [Vagrant + CoreOS](https://github.com/pires/kubernetes-vagrant-coreos-cluster)
* At least 3 nodes available (see [Pod anti-affinity](#pod-anti-affinity))
* `kubectl` configured to access your cluster master API Server
* `openssl` for TLS certificate generation

## Deploy

We will be deploying a cluster of 3 NATS instances, with the following set-up:
- TLS on for clients, but not clustering because peer-auth requires real SANS DNS in certificate
- NATS client credentials: `nats_client_user:nats_client_pwd`
- NATS route/cluster credentials: `nats_route_user:nats_route_pwd`
- Logging: `debug:false`, `trace:true`, `logtime:true`

First, make sure to change `nats.conf` according to your needs.
Then create a Kubernetes configmap to store it:
```bash
kubectl create configmap nats-config --from-file nats.conf
```

Next, we need to generate valid TLS artifacts:
```bash
openssl genrsa -out ca-key.pem 2048
openssl req -x509 -new -nodes -key ca-key.pem -days 10000 -out ca.pem -subj "/CN=kube-ca"
openssl genrsa -out nats-key.pem 2048
openssl req -new -key nats-key.pem -out nats.csr -subj "/CN=kube-nats" -config ssl.cnf
openssl x509 -req -in nats.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out nats.pem -days 3650 -extensions v3_req -extfile ssl.cnf
```

Then, it's time to create a couple Kubernetes secrets to store the TLS artifacts:
- `tls-nats-server` for the NATS server TLS setup
- `tls-nats-client` for NATS client apps setup - one will need it to validate the self-signed certificate
used to secure NATS server
```bash
kubectl create secret generic tls-nats-server --from-file nats.pem --from-file nats-key.pem --from-file ca.pem
kubectl create secret generic tls-nats-client --from-file ca.pem
```

**ATTENTION:** Both using self-signed certificates and using the same certificates for securing
client and cluster connections is a significant security compromise. But for the sake of showing
how it can be done, I'm fine with doing just that.
In an ideal scenario, there should be:
- One centralized PKI/CA
- One certificate for securing NATS route/cluster connections
- One certificate for securing NATS client connections
- TLS route/cluster authentication should be enforced, so one TLS certificate per route/cluster peer
- TLS client authentication should be enforced, so one TLS certificate per client

And finally, we deploy NATS:
```bash
kubectl create -f nats.yml
```

Logs should be enough to make sure everything is working as expected:
```
$ kubectl logs -f nats-0
[1] 2017/12/17 12:38:37.801139 [INF] Starting nats-server version 1.0.4
[1] 2017/12/17 12:38:37.801449 [INF] Starting http monitor on 0.0.0.0:8222
[1] 2017/12/17 12:38:37.801580 [INF] Listening for client connections on 0.0.0.0:4242
[1] 2017/12/17 12:38:37.801772 [INF] TLS required for client connections
[1] 2017/12/17 12:38:37.801778 [INF] Server is ready
[1] 2017/12/17 12:38:37.802078 [INF] Listening for route connections on 0.0.0.0:6222
[1] 2017/12/17 12:38:38.874497 [TRC] 10.244.1.3:33494 - rid:1 - ->> [CONNECT {"verbose":false,"pedantic":false,"user":"nats_route_user","pass":"nats_route_pwd","tls_required":true,"name":"KGMPnL89We3gFLEjmp8S5J"}]
[1] 2017/12/17 12:38:38.956806 [TRC] 10.244.74.2:46018 - rid:3 - ->> [CONNECT {"verbose":false,"pedantic":false,"user":"nats_route_user","pass":"nats_route_pwd","tls_required":true,"name":"Skc5mx9enWrGPIQhyE7uzR"}]
[1] 2017/12/17 12:38:39.951160 [TRC] 10.244.1.4:46242 - rid:4 - ->> [CONNECT {"verbose":false,"pedantic":false,"user":"nats_route_user","pass":"nats_route_pwd","tls_required":true,"name":"0kaCfF3BU8g92snOe34251"}]
[1] 2017/12/17 12:40:38.956203 [TRC] 10.244.74.2:46018 - rid:3 - <<- [PING]
[1] 2017/12/17 12:40:38.958279 [TRC] 10.244.74.2:46018 - rid:3 - ->> [PING]
[1] 2017/12/17 12:40:38.958300 [TRC] 10.244.74.2:46018 - rid:3 - <<- [PONG]
[1] 2017/12/17 12:40:38.961791 [TRC] 10.244.74.2:46018 - rid:3 - ->> [PONG]
[1] 2017/12/17 12:40:39.951421 [TRC] 10.244.1.4:46242 - rid:4 - <<- [PING]
[1] 2017/12/17 12:40:39.952578 [TRC] 10.244.1.4:46242 - rid:4 - ->> [PONG]
[1] 2017/12/17 12:40:39.952594 [TRC] 10.244.1.4:46242 - rid:4 - ->> [PING]
[1] 2017/12/17 12:40:39.952598 [TRC] 10.244.1.4:46242 - rid:4 - <<- [PONG]
```

## Scale

**WARNING:** Due to the [Pod anti-affinity](#pod-anti-affinity) rule, for scaling up to _n_ NATS
instances, one needs _n_ available Kubernetes nodes.

```
kubectl scale statefulsets nats --replicas 5
```

Did it work?

```
NAME             TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)                      AGE
svc/kubernetes   ClusterIP   10.100.0.1   <none>        443/TCP                      1h
svc/nats         ClusterIP   None         <none>        4222/TCP,6222/TCP,8222/TCP   4m

NAME        READY     STATUS    RESTARTS   AGE
po/nats-0   1/1       Running   0          4m
po/nats-1   1/1       Running   0          4m
po/nats-2   1/1       Running   0          4m
po/nats-3   1/1       Running   0          7s
po/nats-4   1/1       Running   0          6s
```

## Access the service

*Don't forget* that services in Kubernetes are only acessible from containers in the cluster.

In this case, we're using a [`headless service`](http://kubernetes.io/v1.1/docs/user-guide/services.html#headless-services).

Just point your client apps to:
```
nats:4222
```

<a id="pod-anti-affinity">

## Pod anti-affinity


One of the main advantages of running NATS on top of Kubernetes is how resilient the cluster becomes,
particularly during node restarts. However if all NATS pods are scheduled onto the same node(s), this
advantage decreases significantly and may even result in service downtime.

It is then **highly recommended** that one adopts [pod anti-affinity](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#inter-pod-affinity-and-anti-affinity-beta-feature)
in order to increase availability. This is enabled by default (see `nats.yml`).
