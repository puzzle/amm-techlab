---
title: "3.2 Event driven architecture with Apache Kafka"
linkTitle: "3.2 Event driven architecture with Apache Kafka"
weight: 32
sectionnumber: 3.2
description: >
   Event driven architecture with Apache Kafka.
---

This lab gives you an introduction to event driven architecture with Apache Kafka. You will deploy an event driven version of the producer-consumer application from [Lab 2](../../../02.0).


## {{% param sectionnumber %}}.1: Apache Kafka

In this section we are going to deploy a [Apache Kafka](https://kafka.apache.org/) cluster with the [Strimzi Operator](https://strimzi.io/) and use it to distribute our events between the microservices. In modern large scale applications messages must be processed, reprocessed, analyzed and handled - often in real time. The key design principles of Kafka were formed based on the need of high-throughput architectures that are easily scalable and provide key features to store and process streamed data.


### {{% param sectionnumber %}}.1.1: Publish-subscribe durable messaging system

[Apache Kafka](https://kafka.apache.org/) is a durable messaging system which uses the publish-subscribe pattern for data exchange. Components publish events to a *topic* and subscribed components will get notified with said event whenever a new message is published. *Topics* represent a data stream which holds a stream of data in temporal order. Applications can send and process records to or from a *topic*. A *record* is a byte array that can store any object in any format. A *record* has four attributes, *key* and *value* are mandatory, and the other attributes, *timestamp* and *headers* are optional. The value can be whatever needs to be sent.

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


## Task {{% param sectionnumber %}}.2: Setup Project

Prepare a new OpenShift project

```bash
oc new-project event-driven-userXY
```


## Task {{% param sectionnumber %}}.3: Deploy an event driven application on OpenShift

Let's get our kafka instance, producer and consumers up and running in the cloud.

> When you like to try it locally with docker-compose, see [Kafka local](../../additional/kafka-local/kafka-local/)

The following Kubernetes-native [custom resource definitions, short crd](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/), defines and configures a Kafka cluster.

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
    storage:
      type: jbod
      volumes:
      - id: 0
        type: persistent-claim
        size: 10Gi
        deleteClaim: false
  zookeeper:
    replicas: 1
    storage:
      type: persistent-claim
      size: 10Gi
      deleteClaim: false
  entityOperator:
    topicOperator: {}
    userOperator: {}

```

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/content/en/docs/03.0/kafka/kafka-cluster.yaml)

With the [Strimzi Operator](https://strimzi.io/) we can manage our Kafka cluster with custom resource definitions. The operator will set up your broker tailored to your needs and configuration. We will also manage our topics with the Strimzi operator.

Create the cluster by creating the crd resource inside your project:

```s
oc apply -f https://raw.githubusercontent.com/puzzle/amm-techlab/master/content/en/docs/03.0/kafka/kafka-cluster.yaml
```

Expected output:

```
kafka.kafka.strimzi.io/amm-techlab created
```

Let's check the created pods for the Kafka cluster:

```s
oc get pods
```

Expected output:

```
NAME                                           READY   STATUS    RESTARTS   AGE
amm-techlab-entity-operator-68c79cc6f8-59kn7   3/3     Running   0          108s
amm-techlab-kafka-0                            2/2     Running   0          2m24s
amm-techlab-zookeeper-0                        1/1     Running   0          2m56s
```

To create a new topic in our Kafka cluster we use another custom resource definition with the following content:

```yml
apiVersion: kafka.strimzi.io/v1beta1
kind: KafkaTopic
metadata:
  name: manual
  labels:
    application: quarkus-techlab
    strimzi.io/cluster: quarkus-techlab
spec:
  partitions: 1
  replicas: 1
  config:
    retention.ms: 7200000
    segment.bytes: 1073741824
```

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/content/en/docs/03.0/kafka/manual-topic.yaml)

This will create the 'manual' topic which allows our microservices to communicate.

```s
oc apply -f https://raw.githubusercontent.com/puzzle/amm-techlab/master/content/en/docs/03.0/kafka/manual-topic.yaml
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
manual   1
```

Now it's time to deploy the application. It consists of the two microservices producer and consumer. The following YAML file defines the needed resources for the producer to run on OpenShift:

```yml
# data-producer.yaml
apiVersion: v1
kind: List
metadata:
  labels:
    application: quarkus-techlab
items:

  - apiVersion: apps/v1
    kind: Deployment
    metadata:
      labels:
        application: quarkus-techlab
      name: data-producer
    spec:
      replicas: 1
      selector:
        matchLabels:
          deployment: data-producer
      strategy:
        type: Recreate
      template:
        metadata:
          labels:
            application: quarkus-techlab
            deployment: data-producer
        spec:
          containers:
            - image: g1raffi/quarkus-techlab-data-producer:kafka
              imagePullPolicy: Always
              livenessProbe:
                failureThreshold: 5
                httpGet:
                  path: /health
                  port: 8080
                  scheme: HTTP
                initialDelaySeconds: 3
                periodSeconds: 20
                successThreshhold: 1
                timeoutSeconds: 15
              readinessProbe:
                failureThreshold: 5
                httpGet:
                  path: /health
                  port: 8080
                  scheme: HTTP
                initialDelaySeconds: 3
                periodSeconds: 20
                successThreshold: 1
                timeoutSeconds: 15
              name: data-producer
              port:
                - containerPort: 8080
                  name: http
                  protocol: TCP
              resources:
                limits:
                  cpu: 1
                  memory: 500Mi
                requests:
                  cpu: 50m
                  memory: 100Mi
      triggers:
        - type: ConfigChange
        - imageChangeParams:
            automatic: true
            containerNames:
              - data-producer
            from:
              kind: ImageStreamTag
              name: data-producer:kafka
          type: ImageChange

  - apiVersion: v1
    kind: Service
    metadata:
      labels:
        application: quarkus-techlab
      name: data-producer
    spec:
      ports:
        - name: data-producer-http
          port: 8080
          protocol: TCP
          targetPort: 8080
      selector:
        deployment: data-producer
      sessionAffinity: None
      type: ClusterIP
```

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/content/en/docs/03.0/kafka/data-producer.yaml)

Apply the content of the YAML file to let OpenShift rollout your freshly created deployment of the producer.

```s
oc apply -f https://raw.githubusercontent.com/puzzle/amm-techlab/master/content/en/docs/03.0/kafka/data-producer.yaml
```

Expected output:

```
deployment.apps/data-producer created
service/data-producer created
```

The consumer has similar resources defined. The [YAML file](https://raw.githubusercontent.com/puzzle/amm-techlab/master/content/en/docs/03.0/kafka/data-consumer.yaml) only differs by image and resource names.

Also apply the resource definition and let OpenShift deploy the consumer:

```s
oc apply -f https://raw.githubusercontent.com/puzzle/amm-techlab/master/content/en/docs/03.0/kafka/data-consumer.yaml
```

Expected output:

```
deployment.apps/data-consumer created
service/data-consumer created
```

Go with the web-console to your OpenShift project (Developer view). There you see the Kafka cluster and the two microservices.

Log into your OpenShift project and check the logs of the data-consumer pod. You can see that he will consume data from the kafka manual topic produced by the data-producer microservice!
