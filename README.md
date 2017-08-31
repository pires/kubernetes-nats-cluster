# kubernetes-nats-cluster
NATS cluster on top of Kubernetes made easy.

[![Docker Repository on Quay](https://quay.io/repository/pires/docker-nats/status "Docker Repository on Quay")](https://quay.io/repository/pires/docker-nats)

## Pre-requisites

* Kubernetes cluster, tested with v1.5.1 on top of:
 * [Vagrant + CoreOS](https://github.com/pires/kubernetes-vagrant-coreos-cluster)
 * Google Container Engine
* `kubectl` configured to access your cluster master API Server
* Optionally, OpenSSL for TLS certificate generation

## Building the image

### `gnatsd` (NATS server)

First, one needs to download the version of the `gnatsd` binary that runs on the official Docker image. This is available at https://github.com/nats-io/nats-docker:

```
curl -o artifacts/gnatsd https://raw.githubusercontent.com/nats-io/nats-docker/master/gnatsd
chmod a+x artifacts/gnatsd
```

Alternatively one can build the binary locally:

```
go get github.com/nats-io/gnatsd
cd $GOPATH/src/github.com/nats-io/gnatsd
git checkout v1.0.2
GOARCH=amd64 GOOS=linux CGO_ENABLED=0 go build -v -a -tags netgo -installsuffix netgo -ldflags "-s -w -X github.com/nats-io/gnatsd/version.GITCOMMIT=`git rev-parse --short HEAD`"
```

Then one needs to copy the resulting `gnatsd` binary to this repository's `artifacts` directory.

### Route checker

Because of issue #2, it was decided to produce an app that makes sure that:

* there's more than once instance of NATS available in the cluster, and if positive
* at least one route is established

```
cd route_checker/
GOARCH=amd64 GOOS=linux CGO_ENABLED=0 go build -v -a -tags netgo -installsuffix netgo
mv route_checker ../artifacts
```

### Kubernetes Deployment

One must change `deployment.yaml` accordingly, commit everything and proceed to push a new tag that will trigger an automatic build:
```
git tag 1.0.2
git push
git push --tags
```

## Deploy

```
kubectl create -f svc.yaml
kubectl create -f deployment.yaml
```

## Scale

```
kubectl scale deployment nats --replicas 3
```

Did it work?

```
$ kubectl get svc,pods
NAME         CLUSTER_IP   EXTERNAL_IP   PORT(S)                      SELECTOR         AGE
kubernetes   10.100.0.1   <none>        443/TCP                      <none>           58m
nats         None         <none>        4222/TCP,6222/TCP,8222/TCP   component=nats   23m

NAME                   READY     STATUS    RESTARTS   AGE
nats-651427393-5zmb7   1/1       Running   0          23m
nats-651427393-dn3rk   1/1       Running   0          21m
nats-651427393-gmc5n   1/1       Running   0          21m
```

## Access the service

*Don't forget* that services in Kubernetes are only acessible from containers in the cluster.

In this case, we're using a [`headless service`](http://kubernetes.io/v1.1/docs/user-guide/services.html#headless-services).

Just point your client apps to:
```
nats:4222
```

## TLS

First, we need to generate a valid TLS certificate:
```
openssl genrsa -out ca-key.pem 2048
openssl req -x509 -new -nodes -key ca-key.pem -days 10000 -out ca.pem -subj "/CN=kube-ca"
openssl genrsa -out nats-key.pem 2048
openssl req -new -key nats-key.pem -out nats.csr -subj "/CN=kube-nats" -config ssl.cnf
openssl x509 -req -in nats.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out nats.pem -days 3650 -extensions v3_req -extfile ssl.cnf
```

Now, it's time to create a Kubernetes secret to store the certificate files:
```
kubectl create secret generic tls-nats --from-file nats.pem --from-file nats-key.pem
```

Finally, deploy a secured NATS cluster:
```
kubectl create -f deployment-tls.yaml
kubectl scale deployment nats --replicas 3
```

## Other configurations

One can configure `gnatsd` through environment variables, to be set on pod descriptors, as listed below:

**SVC** - the headless service name used to discover NATS instances. Defaults to `nats`.

**USER** - the username to authenticate with. Defaults to empty.

**PASS** - the password to authenticate with. Defaults to empty.

**TLS** - whether to enable TLS. Defaults to `false`.

**TLSCERT** - the certificate to use for TLS. Defaults to empty.

**TLSKEY** - the certificate key to use for TLS. Defaults to empty.

**EXTRA** - extra arguments to pass to `gnatsd`, e.g. `-DV`. Defaults to empty.
