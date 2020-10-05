---
title: "3.2 Event driven architecture with Apache Kafka"
linkTitle: "3.2 Event driven architecture with Apache Kafka"
weight: 32
sectionnumber: 3.2
description: >
   Event driven architecture with Apache Kafka.
---

This lab gives you an introduction to event-driven architecture with Apache Kafka. You will deploy an event-driven version of the producer-consumer application from [lab 2](../../../02.0).


## {{% param sectionnumber %}}.1: Apache Kafka

In this section, we are going to deploy a [Apache Kafka](https://kafka.apache.org/) cluster with the [Strimzi Operator](https://strimzi.io/) and use it to distribute our events between the microservices. In modern large scale applications, messages must be processed, reprocessed, analyzed and handled - often in real-time. The key design principles of Kafka were formed based on the need for high-throughput architectures which are easily scalable and provide key features to store and process streamed data.


### {{% param sectionnumber %}}.1.1: Publish-subscribe durable messaging system

[Apache Kafka](https://kafka.apache.org/) is a durable messaging system that uses the publish-subscribe pattern for data exchange. Components publish events to a *topic* and subscribed components will get notified with said event whenever a new message is published. *Topics* represent a data stream that holds a stream of data in a temporal order. Applications can send and process records to or from a *topic*. A *record* is a byte array that can store any object in any format. A *record* has four attributes, *key* and *value* are mandatory, and the other attributes, *timestamp* and *headers* are optional. The value can be whatever needs to be sent.

```
                                                                      +--------------+
                                                       +------------->|   consumer   |
                                                       |              +--------------+
                                                       |
+------------+  message     +------------+  message    |              +--------------+
| publisher  |------------->| topic      |-------------+------------->|   consumer   |
+------------+              +------------+             |              +--------------+
                                                       |
                                                       |              +--------------+
                                                       +------------->|   consumer   |
                                                                      +--------------+
```

There are four important parts of any Kafka system:

* *Broker*: The broker handles all requests from clients (produce, consume and metadata) and keeps data replicated within the cluster. There can be one or more brokers in a cluster.
* *Zookeeper*: The Zookeeper organizes the state of the cluster (brokers, topics and users).
* *Producer*: The producer sends records to the broker.
* *Consumer*: The consumer subscribes to a topic and consumes records from the broker.

If you want to dive deeper into the Kafka world take a look at the official [documentation](https://kafka.apache.org/documentation/).


## Task {{% param sectionnumber %}}.2: Lap Setup

This lab bases on [lab 2](../../../02.0). Make sure that you are in the same OpenShift project.

```s
oc project
```

```
Using project "userXY" on server "https://api.techlab.openshift.ch:6443".
```

The returned project should be your user name.

{{% alert  color="primary" %}}When the application does not run correctly, see the solution section of lab 2 or ask for assistance.{{% /alert %}}


## Task {{% param sectionnumber %}}.3: Deploy and configure Kafka on OpenShift

Let's get our Kafka instance up and running in the cloud and configure it for the event-driven application.

{{% alert  color="primary" %}}When you like to try it locally with docker-compose, see [Kafka local](../../additional/kafka-local/kafka-local/){{% /alert %}}

The following Kubernetes-native [custom resource definitions, short crd](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/), defines and configures a Kafka cluster.

Create a file called `<workspace>/kafka-cluster.yaml` with the following content:

```yml
apiVersion: kafka.strimzi.io/v1beta1
kind: Kafka
metadata:
  name: amm-techlab
  labels:
    application: amm-techlab
spec:
  kafka:
    version: 2.5.0
    replicas: 1
    listeners:
      plain: {}
      tls: {}
    config:
      auto.create.topics.enable: false
      offsets.topic.replication.factor: 1
      transaction.state.log.replication.factor: 1
      transaction.state.log.min.isr: 1
      log.message.format.version: "2.5"
    resources:
      requests:
        memory: 128Mi
        cpu: "50m"
      limits:
        memory: 4Gi
        cpu: "2"
    storage:
      type: jbod
      volumes:
      - id: 0
        type: persistent-claim
        size: 10Gi
        deleteClaim: false
  zookeeper:
    replicas: 1
    resources:
      requests:
        memory: 128Mi
        cpu: "50m"
      limits:
        memory: 4Gi
        cpu: "2"
    storage:
      type: persistent-claim
      size: 10Gi
      deleteClaim: false
  entityOperator:
    topicOperator: {}
    userOperator: {}
```

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/03.0/3.2/kafka-cluster.yaml)

With the [Strimzi Operator](https://strimzi.io/) we can manage our Kafka cluster with custom resource definitions. The operator is already installed in our techlab cluster. It will set up your broker tailored to your needs and configuration. We will also manage our topics with the Strimzi operator.

Create the cluster by creating the crd resource inside your project:

```s
oc apply -f kafka-cluster.yaml
```

Expected output:

```
kafka.kafka.strimzi.io/amm-techlab created
```

Let's check the created pods for the Kafka cluster:

```s
oc get pods
```

Expected Kafka pods after all pods have been started:

```
NAME                                           READY   STATUS    RESTARTS   AGE
amm-techlab-entity-operator-68c79cc6f8-59kn7   3/3     Running   0          108s
amm-techlab-kafka-0                            2/2     Running   0          2m24s
amm-techlab-zookeeper-0                        1/1     Running   0          2m56s
```

To create a new topic in our Kafka cluster we use another custom resource definition. Create a file called `<workspace>/manual-topic.yaml` with the following content:

```yml
apiVersion: kafka.strimzi.io/v1beta1
kind: KafkaTopic
metadata:
  name: manual
  labels:
    application: amm-techlab
    strimzi.io/cluster: amm-techlab
spec:
  partitions: 1
  replicas: 1
  config:
    retention.ms: 7200000
    segment.bytes: 1073741824
```

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/03.0/3.2/manual-topic.yaml)

This will create the 'manual' topic, which allows our microservices to communicate.

```s
oc apply -f manual-topic.yaml
```

Expected output:

```
kafkatopic.kafka.strimzi.io/manual created
```

Because the topics are resources, we can query them:

```s
oc get KafkaTopic
```

The listing should show one topic.

```
NAME     PARTITIONS   REPLICATION FACTOR
manual   1            1
```

As an alternative we can also connect to the kafka server and list all topics

You need to rsh into the kafka pod

```bash
oc rsh amm-techlab-kafka-0
```

The helper scripts within the bin directory allow you to query your kafka server. Execute the following command to list all topics, including the topic we've created before.

```bash
./bin/kafka-topics.sh --bootstrap-server localhost:9092  --describe
```

This listing should also show the `manual` topic.

{{% alert  color="primary" %}}Press `Ctrl+D` to leave the container.{{% /alert %}}


## Task {{% param sectionnumber %}}.4: Change your application to event driven

Now it's time to change your producer-consumer application from REST to event-driven. The Kafka cluster is up and running.


### Task {{% param sectionnumber %}}.4.1: Update the producer

We do not rebuild our producer. Instead, we use a prepared container image. Do two changes inside your file `<workspace>/deploymentConfig.yaml`. Change the image to `puzzle/quarkus-techlab-data-producer:kafka` and remove the ImageChange trigger.

If you're interested in the code changes needed to connect to the kafka server, checkout the [kafka branch of the producer](https://github.com/puzzle/quarkus-techlab-data-producer/tree/kafka).

```
{{< highlight YAML "hl_lines=22 27-28" >}}
apiVersion: v1
kind: DeploymentConfig
metadata:
  labels:
    application: amm-techlab
  name: data-producer
spec:
  replicas: 1
  selector:
    deploymentConfig: data-producer
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        application: amm-techlab
        deploymentConfig: data-producer
    spec:
      containers:
        - image: puzzle/quarkus-techlab-data-producer:kafka
          imagePullPolicy: Always

          ...

  triggers:
    - type: ConfigChange
{{< / highlight >}}
```

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/03.0/3.2/deploymentConfig.yaml)

Apply the updated content of the YAML file to let OpenShift rollout your freshly created deployment of the producer.

```s
oc apply -f deploymentConfig.yaml --overwrite=true --force=true
```

{{% alert  color="primary" %}}We need the additional flags to reset the port changes from the previous lab.{{% /alert %}}

Expected output:

```
deploymentconfig.apps.openshift.io/data-producer configured
```


### Task {{% param sectionnumber %}}.4.2: Update the consumer

Also, the consumer has a prepared container image. We only have to change the image to `puzzle/quarkus-techlab-data-consumer:kafka`.

The file from lab 2 `<workspace>/consumer.yaml` defines all needed resources as a list.
Instead of the OpenShift DeploymentConfig of the producer, the consumer uses a Kubernetes-native Deployment. There you change the used container image.

Checkout the [Consumer Sourcecode (kafka branch)](https://github.com/puzzle/quarkus-techlab-data-consumer/tree/kafka) to see what changed in the consumer service.

./kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic manual --from-beginning

```
{{< highlight YAML "hl_lines=21" >}}
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: data-consumer
    application: amm-techlab
  name: data-consumer
spec:
  replicas: 1
  selector:
    matchLabels:
      deployment: data-consumer
  strategy: {}
  template:
    metadata:
      labels:
        deployment: data-consumer
        app: data-consumer
    spec:
      containers:
      - image: puzzle/quarkus-techlab-data-consumer:kafka
        imagePullPolicy: Always
        ...
{{< / highlight >}}
```

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/03.0/3.2/consumer.yaml)


Also apply the updated resource definition and let OpenShift deploy the consumer:

```s
oc apply -f consumer.yaml
```

Expected output:

```
deployment.apps/data-consumer configured
service/data-consumer unchanged
route.route.openshift.io/data-consumer unchanged
```

Go with the web-console to your OpenShift project (Developer view). There you see the Kafka cluster and the two microservices.

Log into your OpenShift project and check the logs of the data-consumer pod. You can see that he will consume data from the Kafka manual topic produced by the data-producer microservice!


### Task {{% param sectionnumber %}}.4.3: Verify the events on the kafka topic

To verify the produced events end up in the `manual` topic, we can once again rsh into the kafka pod and use the helper scripts.

```bash
oc rsh amm-techlab-kafka-0
```

Then execute the following command to read events from the topic

```bash
./bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic manual
```

Expected result, something similar to:

```bash
{"data":0.14970117407591477}
{"data":0.3119723463354409}
...
{"data":0.48397732353720324}
```

{{% alert title="Note" color="primary" %}} Use the `--from-beginning` param to read the whole topic {{% /alert %}}

{{% alert title="Note" color="primary" %}}Stop this consumer inside the container by pressing `Ctrl+C` and `Ctrl+D` to leave the container.{{% /alert %}}


## Solution

The needed resource files are available inside the folder *manifests/03.0/3.2/*.

If you weren't successful, you can update your project with the solution by executing this command:

```s
oc apply -f manifests/03.0/3.2/
```
