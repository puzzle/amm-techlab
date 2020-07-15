---
title: "5.5.1 Operators"
linkTitle: "Operators"
weight: 551
sectionnumber: 5.5.1
description: >
  Operators.
---

## TODO

* [ ] Testen und durchspielen
* [ ] Intro Text auf Englisch übersetzen.
* [ ] Synchen mit [APPUiO Lab](https://github.com/appuio/techlab/blob/lab-4.3/labs/07_operators.md)


Operators sind eine Art und Weise wie man Kubernetes-native Applikationen paketieren, deployen und verwalten kann. Kubernetes-native Applikationen sind Applikationen, die einerseits in Kubernetes/OpenShift deployed sind und andererseits auch über das Kubernetes/OpenShift-API (kubectl/oc) verwaltet werden. Seit OpenShift 4 verwendet auch OpenShift selber eine Reihe von Operators um den OpenShift-Cluster, also sich selber, zu verwalten.


## Einführung / Begriffe

Um zu verstehen, was ein Operator ist und wie er funktioniert, schauen wir zunächst den sogenannten Controller an, da Operators auf dessen Konzept basieren.


### Controller

Ein Controller besteht aus einem Loop, in welchem immer wieder der gewünschte Zustand (_desired state_) und der aktuelle Zustand (_actual state/obseved state_) des Clusters gelesen werden. Wenn der aktuelle Zustand nicht dem gewünschten Zustand entspricht, versucht der Controller den gewünschten Zustand herzustellen. Der gewünschte Zustand wird mit Ressourcen (Deployments, ReplicaSets, Pods, Services, etc.) beschrieben.

Die ganze Funktionsweise von OpenShift/Kubernetes basiert auf diesem Muster. Auf dem Master (controller-manager) laufen eine Vielzahl von Controllern, welche aufgrund von Ressourcen (ReplicaSets, Pods, Services, etc.) den gewünschten Zustand herstellen. Erstellt man z.B. ein ReplicaSet, sieht dies der ReplicaSet-Controller und erstellt als Folge die entsprechende Anzahl von Pods.

__Optional__: Der Artikel [The Mechanics of Kubernetes](https://medium.com/@dominik.tornow/the-mechanics-of-kubernetes-ac8112eaa302) gibt einen tiefen Einblick in die Funktionsweise von Kubernetes. In der Grafik im Abschnitt _Cascading Commands_ wird schön aufgezeigt, dass vom Erstellen eines Deployments bis zum effektiven Starten der Pods vier verschiedene Controller involviert sind.


### Operator

Ein Operator ist ein Controller, welcher dafür zuständig ist, eine Applikation zu installieren und zu verwalten. Ein Operator hat also applikations-spezifisches Wissen. Dies ist insbesondere bei komplexeren Applikationen nützlich, welche aus verschiedenen Komponenten bestehen oder zusätzlichen Administrationsaufwand erfordern (z.B. neu gestartete Pods müssen zu einem Applikations-Cluster hinzugefügt werden, etc.).

Auch für den Operator muss der gewünschte Zustand durch eine Ressource abgebildet werden. Dazu gibt es sogenannte Custom Resource Definitions (CRD). Mit CRDs kann man in OpenShitf/Kubernetes beliebige neue Ressourcen definieren. Der Operator schaut dann konstant (_watch_), ob Custom Resources verändert werden, für welche der Operator zuständig ist und führt entsprechend der Zielvorgabge in der Custom Resource Aktionen aus.

Operators erleichtern es also komplexere Applikationen zu betreiben, da das Management vom Operator übernommen wird. Allfällige komplexe Konfigurationen werden durch Custom Resources abstrahiert und Betriebsaufgaben wie Backups oder das Rotieren von Zertifikaten etc. können auch vom Operator ausgeführt werden.


## Installation eines Operators

Ein Operator läuft wie eine normale Applikation als Pod im Cluster. Zur Installation eines Operators gehören in der Regel die folgenden Ressourcen:

* ***Custom Resource Definition***: Damit die neuen Custom Resources angelegt werden können, welche der Operator behandelt, müssen die entsprechenden CRDs installiert werden.
* ***Service Account***: Ein Service Account mit welchem der Operator läuft.
* ***Role und RoleBinding***: Mit einer Role definiert man alle Rechte, welche der Operator braucht. Dazu gehören mindestens Rechte auf die eigene Custom Resource. Mit einem RoleBinding wird die neue Role dem Service Account des Operators zugewiesen.
* ***Deployment***: Ein Deployment um den eigentlichen Operator laufen zu lassen. Der Operator läuft meistens nur einmal (Replicas auf 1 eingestellt), da sich sonst die verschiedenen Operator-Instanzen gegenseitig in die Quere kommen würden.

Auf OpenShift 4 ist standardmässig der Operator Lifecycle Manager (OLM) installiert. OLM vereinfacht die Installation von Operators. Der OLM erlaubt es uns, aus einem Katalog einen Operator auszuwählen (_subscriben_), welcher dann automatisch installiert und je nach Einstellung auch automatisch upgedated wird.

Als Beispiel installieren wir in den nächsten Schritten den ETCD-Operator. Normalerweise ist das Aufsetzen eines ETCD-Clusters ein Prozess mit einigen Schritten und man muss viele Optionen zum Starten der einzelnen Cluster-Member kennen. Der ETCD-Operator erlaubt es uns mit der EtcdCluster-Custom-Resource ganz einfach einen ETCD-Cluster aufzusetzen. Dabei brauchen wir kein detailliertes Wissen über ETCD, welches normalerweise für das Setup notwendig wäre, da dies alles vom Operator übernommen wird.
Wie für ETCD gibt es auch für viele andere Applikationen vorgefertigte Operators, welche einem den Betrieb von diesen massiv vereinfachen.


## {{% param sectionnumber %}}.1 Lab: Create a etcd Cluster

Centrally we have the Operator Lifecycle Manager installed. It provides us various operators ready to be consumed within our project.

We will deploy a etcd-cluster and see what we can do.


### Subscription

To be able to consume an operator we will create a subscription within a project. This will enable the CRDs, as well as install the operator that watches our CRDs as well as the deployed clusters.

Create project:

```bash
oc new-project operator-userXY
```

Subscribe to the etcd operator, by creating a file called `etcd-subscription.yaml` with the following content:

```yaml
# etcd-subscription.yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  generateName: etcd-
  namespace: operator-userXY
  name: etcd
spec:
  source: rh-operators
  name: etcd
  startingCSV: etcdoperator.v0.9.2
  channel: alpha
```

Now subscribe using the file:


```bash
oc create -f etcd-subscription.yaml
```

```bash
oc get pods
```

You can also subscribe to the operator through the Console, though not all integration might be ready, due to being technical preview by default.

You can see the running operator:

```bash
oc get pods
```

Once this is done, you are able to deploy a cluster, by using a crd.

You can do this by creating a file called `etcd-cluster.yaml` with the following content:

```yaml
# etcd-cluster.yaml
apiVersion: "etcd.database.coreos.com/v1beta2"
kind: "EtcdCluster"
metadata:
  name: "example-etcd-cluster"
spec:
  size: 3
  version: "3.1.10"
```

```bash
oc create -f etcd-cluster.yaml
```

Your cluster will be bootstrapped and will become ready:

```bash
oc get pods -w
oc get service
```

Describing the configured CRD gives us more information about the deployment:

```bash
oc describe EtcdCluster example-etcd-cluster
```

We can also store something within our cluster:

```bash
oc rsh example-etcd-cluster-XYZ
export ETCDCTL_API=3
etcdctl get foo
etcdctl put foo bar
etcdctl get foo
```


### Recovery

The operator is watching the deployed cluster and will recover it from failures. This is not a feature driven by a StatefulSet or a DeploymentConfig, rather the operator watches the deployed cluster and ensures it is kept in the desired overall state:

```bash
oc delete pod example-etcd-cluster-XYZ
oc get pods
oc rsh example-etcd-cluster-ABC
export ETCDCTL_API=3
etcdctl get foo
```

See how the changes got logged.

```bash
oc describe EtcdCluster example-etcd-cluster
```


### Updating

But well it looks like we didn't deploy a recent enough version:

```bash
oc describe pod -l app=etcd | grep -E 'Image:.*etcd' | uniq
    Image:         quay.io/coreos/etcd:v3.1.10
```

Let's update the cluster. This is done by patching the CRD to a new version

```bash
oc get EtcdCluster example-etcd-cluster -o yaml
# check the version
```

Now we can either edit the current deployment or supply an update to the spec:

```yaml
# etcd-update.yaml
apiVersion: "etcd.database.coreos.com/v1beta2"
kind: "EtcdCluster"
metadata:
  name: "example-etcd-cluster"
spec:
  size: 3
  version: "3.2.13"
```

```bash
oc apply -f etcd-update.yaml
```

Now watch how each member is being updated to 3.2.13 until all of them are updated:

```bash
oc describe EtcdCluster example-etcd-cluster
# watch the events of the resource or the overall events
oc get events
# in the end all images should be updated
oc describe pod -l app=etcd | grep -E 'Image:.*etcd' | uniq
    Image:         quay.io/coreos/etcd:v3.2.13
```


### Scale Up

Works exactly the same way:

```yaml
# etcd-scaleup.yaml
apiVersion: "etcd.database.coreos.com/v1beta2"
kind: "EtcdCluster"
metadata:
  name: "example-etcd-cluster"
spec:
  size: 5
  version: "3.2.13"
```

```bash
oc apply -f etcd-scaleup.yaml
oc get events -w
# until all are up
oc get pods -l app=etcd
```


### Scale Down

Is also supported with this operator. Do you figure out how?
