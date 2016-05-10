# kubernetes-nats-cluster
NATS cluster on top of Kubernetes made easy.

[![Docker Repository on Quay](https://quay.io/repository/pires/docker-nats/status "Docker Repository on Quay")](https://quay.io/repository/pires/docker-nats)

## Pre-requisites

* Kubernetes cluster (tested with v1.2.4 on top of [Vagrant + CoreOS](https://github.com/pires/kubernetes-vagrant-coreos-cluster))
* GKE 1.1.x and 1.2.x
* `kubectl` configured to access your cluster master API Server

## How I built the image

First, one needs to build `gnatsd` that supports the topology gossiping released with version `0.8.0`..
```
cd $GOPATH/src/github.com/nats-io/gnatsd
git pull --rebase origin master
git co tags/v0.8.0
GOARCH=amd64 GOOS=linux go build
```

Then, I copied the resulting binary to this repository `artifacts` folder and proceed to push a new tag that will trigger an automatic build:
```
docker build -t quay.io/pires/docker-nats:0.8.0 .
git tag 0.8.0
git push
```

## Deploy

```
kubectl create -f service-account.yaml
kubectl create -f svc-nats.yaml
kubectl create -f rc-nats.yaml
```

## Scale

```
kubectl scale rc/nats --replicas=3
```

Did it work?

```
$ kubectl get svc,rc,pods
NAME         CLUSTER_IP   EXTERNAL_IP   PORT(S)                      SELECTOR         AGE
kubernetes   10.100.0.1   <none>        443/TCP                      <none>           58m
nats         None         <none>        4222/TCP,6222/TCP,8222/TCP   component=nats   23m
CONTROLLER   CONTAINER(S)   IMAGE(S)                            SELECTOR         REPLICAS   AGE
nats         nats           quay.io/pires/docker-nats:0.8.0   component=nats   3          23m
NAME         READY     STATUS    RESTARTS   AGE
nats-c3eu2   1/1       Running   0          23m
nats-ruu5q   1/1       Running   0          21m
nats-dke71   1/1       Running   0          21m
```

## Access the service

*Don't forget* that services in Kubernetes are only acessible from containers in the cluster.

In this case, we're using a [`headless service`](http://kubernetes.io/v1.1/docs/user-guide/services.html#headless-services).

Just point your client apps to:
```
nats:4222
```
