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


Operators are a way to package, deploy and manage Kubernetes-native applications. Kubernetes-native applications are applications that are deployed in Kubernetes/OpenShift and managed via the Kubernetes/OpenShift API (kubectl/oc). Since the introduction of OpenShift 4, OpenShift itself uses several operators to manage the OpenShift cluster.


## Introduction / Terms

To understand, what an operator is and how it works, we first look at the so-called controller, because operators are based on its concept.


### Controller

A controller consists of a loop, in which the desired state and the actual / obseved state of the cluster are read again and again. If the actual / obseved state isn't matching the desired state, the controller tries to establish the desired state. The desired state is described with resources (Deployments, ReplicaSets, Pods, Services, etc.).

The whole functionality of OpenShift/Kubernetes is based on this pattern. On the master (controller-manager) several controllers run, which create the desired state based on resources (ReplicaSets, Pods, Services, etc.). For example, if a ReplicaSet is created, the ReplicaSet controller sees this and thus creates the corresponding number of Pods.

__Optional__: The article [The Mechanics of Kubernetes](https://medium.com/@dominik.tornow/the-mechanics-of-kubernetes-ac8112eaa302) provides a deeper insight into how Kubernetes works. The graphic in the Cascading Commands section illustrates, that four different controllers are involved from the time a deployment is created until the pods are effectively started.


### Operator

An operator is a controller that is responsible for installing and managing an application. An operator, therefore, has application-specific knowledge. This is especially useful for more complex applications that consists of different components or require additional administration effort (e.g. newly started Pods must be added to an application cluster, etc.).

Also for the operator, the desired state has to be represented by a resource. For this purpose, there are so-called Custom Resource Definitions (CRD). With CRDs you can define any new resources in OpenShift/Kubernetes. The operator then constantly watches, whether its Custom Resources are changed, and executes actions according to the target in the Custom Resource.

Operators make it easier to run more complex applications because the operator takes over the management. Any complex configurations are abstracted by Custom Resources and operational tasks such as backups or rotating certificates etc. can also be performed by the operator.


## Installation of an operator

An operator runs like a normal application as a pod in a cluster. The following resources are usually required to install an operator:

* ***Custom Resource Definition***: To create the new Custom Resources that are being handled by the Operator, the appropriate CRDs must be installed.
* ***Service Account***: A service account with which the operator runs.
* ***Role und RoleBinding***: With a Role, you define all rights the operator needs. This includes at least rights to its custom resource. With a RoleBinding the new Role is assigned to the Service Account of the Operator.
* ***Deployment***: A deployment to run the actual operator. The operator usually runs only once (replicas set to 1), otherwise, the different operator instances would get in each other's way.

On OpenShift 4 the Operator Lifecycle Manager (OLM) is installed by default. OLM simplifies the installation of operators. OLM allows us to select an operator from a catalog (subscribe), which is then automatically installed and updated depending on the settings.

As an example, we will install the ETCD operator in the next steps. Normally, setting up an ETCD cluster is a process with many steps and you have to be familiar with several options to start the individual cluster members. The ETCD operator allows us to easily set up an ETCD cluster with the Etcd-Cluster-Custom-Resource. We don't need a huge know-how about ETCD, which would normally be required for the setup, because this is all done by the operator.
As for ETCD, there are pre-built operators for many other applications, which massively simplify their operation.

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
