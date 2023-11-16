# ProxySQL on Kubernetes

These charts are adapted from [the offical k8s repo](https://github.com/ProxySQL/kubernetes), which I have been told is not technically canonical, and is in fact experimental. Because of that, I have felt empowered to delete a bunch of things that we don't need and make some changes to the rest.

* We're using the [latest proxysql docker image](https://hub.docker.com/r/proxysql/proxysql) rather than some random one they created.
* Well ACTUALLY, I've built a [Dockerfile](Dockerfile) that automatically installs a bunch of tooling so that I don't have to keep doing it over and over everytime I reinstall.


## Cluster core pods (3)

Charts for this deployment (statefulset technically) are in the [core](core) directory.

Install the core pods via:

```shell
# create the namespace if it doesn't exist
kubectl create ns proxysql

helm install proxysql-core -n proxysql ./helm/proxysql/core
```

The cluster core pods is a small (3 nodes currently, but can be scaled down as needed) deployment of proxysql servers that communicate with each other. These instances will not serve proxysql traffic, and exist only to manage the configuration of the rest of proxysql cluster (specifically the satellites).

Configuration changes on any of these pods will be propagated to the other pods in the core deployment, and to any  satellite pod that is connected to the cluster.

Resources created by the charts:

```
23:19:31 <nick@marais:ExampleProxySQLSetup(kuzmik/k8s-cluster)(✘!?) $ > k get all
NAME                                READY   STATUS    RESTARTS   AGE
pod/proxysql-core-0   1/1     Running   0          28s
pod/proxysql-core-1   1/1     Running   0          26s
pod/proxysql-core-2   1/1     Running   0          15s

NAME                                  TYPE        CLUSTER-IP        EXTERNAL-IP   PORT(S)    AGE
service/proxysql-core   ClusterIP   192.168.194.163   <none>        6032/TCP   28s

NAME                                           READY   AGE
statefulset.apps/proxysql-core   3/3     28s
```

## Cluster satellite pods (3)

Charts for this deployment are in the [satellite](satellite) directory.

Install the satellite cluster via:

```shell
helm install proxysql-satellite -n proxysql ./helm/proxysql/satellite
```

This is the part of the proxysql cluster that will actually serve mysql traffic. On boot, each pod will connect to the `proxysql-core` service (see above), which will distribute the configuration to the pod. This will allow scaling in and out to be easier and any new pods will automatically join the "cluster" so to speak.

Configuration changes on these pods will NOT propagate up to the core pods, and therefore will not make it to any other proxysql pod.

## Known Issues

- If you deploy core and satellite at the same time, the satellite will attempt to connect to the core cluster immediately and fail because the core service isn't up yet. The satellite container will get killed and on restart it will connect properly.

## Misc

* How to [Disable portions of the annotations feature](https://github.com/sysown/proxysql/issues/4325#issuecomment-1681630863)
