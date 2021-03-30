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


## Task {{% param sectionnumber %}}.2: Check project setup

We first check that the project is ready for the lab.

Ensure that the `LAB_USER` environment variable is set.

```bash
echo $LAB_USER
```

If the result is empty, set the `LAB_USER` environment variable.

<details><summary>command hint</summary>

```bash
export LAB_USER=<username>
```

</details><br/>


Change to your main Project.

<details><summary>command hint</summary>

```bash
oc project $LAB_USER
```

</details><br/>


## Task {{% param sectionnumber %}}.3: Deploy and configure Kafka on OpenShift

Let's get our Kafka instance up and running in the cloud and configure it for the event-driven application.

{{% alert  color="primary" %}}When you like to try it locally with docker-compose, see [Kafka local](../../additional/kafka-local/kafka-local/){{% /alert %}}

The following Kubernetes-native [custom resource definitions, short crd](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/), defines and configures a Kafka cluster.

Create a file called `<workspace>/kafka-cluster.yaml` with the following content:

{{< highlight yaml >}}{{< readfile file="manifests/03.0/3.2/kafka-cluster.yaml" >}}{{< /highlight >}}

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/03.0/3.2/kafka-cluster.yaml)

With the [Strimzi Operator](https://strimzi.io/) we can manage our Kafka cluster with custom resource definitions. The operator is already installed in our techlab cluster. It will set up your broker tailored to your needs and configuration. We will also manage our topics with the Strimzi operator.

Create the cluster by creating the crd resource inside your project. To do so, apply the content of your `kafka-cluster.yaml` file.

<details><summary>command hint</summary>

```s
oc apply -f kafka-cluster.yaml
```

</details><br/>

Expected output:

```
kafka.kafka.strimzi.io/amm-techlab created
```

Let's check the created pods for the Kafka cluster:

```s
oc get pods
```

Expected Kafka pods after all pods have been started (This may take a few minutes):

```
NAME                                           READY   STATUS    RESTARTS   AGE
amm-techlab-entity-operator-68c79cc6f8-59kn7   3/3     Running   0          108s
amm-techlab-kafka-0                            1/1     Running   0          2m24s
amm-techlab-zookeeper-0                        1/1     Running   0          2m56s
```

To create a new topic in our Kafka cluster we use another custom resource definition. Create a file called `<workspace>/manual-topic.yaml` with the following content:

{{< highlight yaml >}}{{< readfile file="manifests/03.0/3.2/manual-topic.yaml" >}}{{< /highlight >}}

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/03.0/3.2/manual-topic.yaml)

This file defines the 'manual' topic, which allows our microservices to communicate.

Create the Kafka topic by applying this file.

<details><summary>command hint</summary>

```s
oc apply -f manual-topic.yaml
```

</details><br/>

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

```
Topic: manual   PartitionCount: 1       ReplicationFactor: 1    Configs: segment.bytes=1073741824,retention.ms=7200000,message.format.version=2.5-IV0
        Topic: manual   Partition: 0    Leader: 0       Replicas: 0     Isr: 0
```

{{% alert  color="primary" %}}Press `Ctrl+D` to leave the container.{{% /alert %}}


## Task {{% param sectionnumber %}}.4: Change your application to event driven

Now it's time to change your producer-consumer application from REST to event-driven. The Kafka cluster is up and running.


### Task {{% param sectionnumber %}}.4.1: Update the producer

To update the producer we use a prepared container image. If you're interested in the code changes needed to connect to the kafka server, check the [kafka branch of the producer](https://github.com/puzzle/quarkus-techlab-data-producer/tree/kafka).

Because that we do not rebuild the producer, the usage of an OpenShift DeploymentConfig is not necessary any more. We change te producer to use a Kubernetes-native Deployment. The consumer already uses a Deployment. You could check the resource definition file `<workspace>/consumer.yaml` for the needed adaptations.

Do following changes inside your file `<workspace>/producer.yaml`:

* Change the type to Deployment (including api version),
* remove the annotations,
* update the selector,
* add label `app`,
* rename label `deploymentConfig` to `deployment`,
* change the image to `quay.io/puzzle/quarkus-techlab-data-producer:jaegerkafka`
* and remove the triggers.

```
{{< highlight YAML "hl_lines=1-2 4 12-13 20-21 24 58" >}}
apiVersion: apps/v1
kind: Deployment
metadata:
  # Remove annotations from deployment config!
  labels:
    app: data-producer
    application: amm-techlab
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
        application: amm-techlab
        deployment: data-producer
        app: data-producer
    spec:
      containers:
        - image: quay.io/puzzle/quarkus-techlab-data-producer:jaegerkafka
          imagePullPolicy: Always
          livenessProbe:
            failureThreshold: 5
            httpGet:
              path: /health/live
              port: 8080
              scheme: HTTP
            initialDelaySeconds: 3
            periodSeconds: 20
            successThreshold: 1
            timeoutSeconds: 15
          readinessProbe:
            failureThreshold: 5
            httpGet:
              path: /health/ready
              port: 8080
              scheme: HTTP
            initialDelaySeconds: 3
            periodSeconds: 20
            successThreshold: 1
            timeoutSeconds: 15
          name: data-producer
          ports:
            - containerPort: 8080
              name: http
              protocol: TCP
          resources:
            limits:
              cpu: '1'
              memory: 500Mi
            requests:
              cpu: 50m
              memory: 100Mi
      # Remove triggers from deployment config!
{{< / highlight >}}
```

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/03.0/3.2/producer.yaml)

First we have to delete the DeploymentConfig of the producer.

<details><summary>command hint</summary>

```s
oc delete DeploymentConfig data-producer
```

</details><br/>

Expected output:

```
deploymentconfig.apps.openshift.io "data-producer" deleted
```

Now we check, that our resource definition has been modified correctly.
This can be done with `oc apply` as *dry-run* (do not apply changes) in combination with *validate*:

```s
oc apply -f producer.yaml --validate --dry-run=client
```

The output must be `deployment.apps/data-producer created (dry run)` before you can go on.

Apply the updated content of the YAML file to let OpenShift rollout your freshly created Deployment of the producer.

<details><summary>command hint</summary>

```s
oc apply -f producer.yaml
```

</details><br/>

Expected output:

```
deployment.apps/data-producer created
```

Do the following changes inside your file `<workspace>/svc.yaml`. Update the label selector from `deploymentConfig: data-producer` to `deployment: data-producer`. Otherwise the Service will not find any Pods to route the traffic into.

{{< highlight yaml "hl_lines=14" >}}{{< readfile file="manifests/03.0/3.2/svc.yaml" >}}{{< /highlight >}}

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/03.0/3.2/svc.yaml)

Apply the updated Service manifest.

<details><summary>command hint</summary>

```s
oc apply -f svc.yaml
```

</details><br/>

Expected output:

```
service/data-producer configured
```


### Task {{% param sectionnumber %}}.4.2: Verify the events on the kafka topic

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

{{% alert title="Note" color="primary" %}} Use the `\--from-beginning` param to read the whole topic {{% /alert %}}

{{% alert title="Note" color="primary" %}}Stop this consumer inside the container by pressing `Ctrl+C` and `Ctrl+D` to leave the container.{{% /alert %}}


### Task {{% param sectionnumber %}}.4.3: Update the consumer

The custom container image has kafka capabilities.

We need to configure the consumer by it's environment to use kafka. This we do with a [ConfigMap](https://kubernetes.io/docs/concepts/configuration/configmap/).
Prepare a file inside your workspace `<workspace>/consumerConfigMap.yaml` and add the following resource configuration:

{{< highlight yaml >}}{{< readfile file="manifests/03.0/3.2/consumerConfigMap.yaml" >}}{{< /highlight >}}

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/03.0/3.2/consumerConfigMap.yaml)

Let's create the ConfigMap

<details><summary>command hint</summary>

```BASH
oc apply -f consumerConfigMap.yaml
```

</details><br/>

Expected output:

```
configmap/consumer-config created
```

Next step is to include the ConfigMap to the consumer pod to define the environment.
The file from lab 2 `<workspace>/consumer.yaml` defines all needed resources as a list. We only have to integrate the `consumer-config` ConfigMap to the Deployment and change the Docker image tag to `:jaegerkafka`.

```
{{< highlight YAML "hl_lines=23-26" >}}
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
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        deployment: data-consumer
        app: data-consumer
        application: amm-techlab
    spec:
      containers:
        - image: quay.io/puzzle/quarkus-techlab-data-consumer:jaegerkafka
          envFrom:
            - configMapRef:
                name: consumer-config
          imagePullPolicy: Always
        ...
{{< / highlight >}}
```

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/03.0/3.2/consumer.yaml)


Also apply the updated resource definition and let OpenShift deploy the consumer.

<details><summary>command hint</summary>

```s
oc apply -f consumer.yaml
```

</details><br/>

Expected output:

```
deployment.apps/data-consumer configured
service/data-consumer unchanged
route.route.openshift.io/data-consumer unchanged
```

Go with the web-console to your OpenShift project (Developer view). There you see the Kafka cluster and the two microservices.

Check the logs of the data-consumer pod. You can see that he will consume data from the Kafka manual topic produced by the data-producer microservice!

Example log output:

```bash
2020-11-19 14:35:59,009 INFO  [ch.puz.qua.rea.bou.ReactiveDataConsumer] (vert.x-eventloop-thread-0) Received reactive message: {"data":0.30638741165836225}
2020-11-19 14:36:01,009 INFO  [ch.puz.qua.rea.bou.ReactiveDataConsumer] (vert.x-eventloop-thread-0) Received reactive message: {"data":0.08769436937761332}
2020-11-19 14:36:03,008 INFO  [ch.puz.qua.rea.bou.ReactiveDataConsumer] (vert.x-eventloop-thread-0) Received reactive message: {"data":0.9658464575333938}
2020-11-19 14:36:05,009 INFO  [ch.puz.qua.rea.bou.ReactiveDataConsumer] (vert.x-eventloop-thread-0) Received reactive message: {"data":0.6341857869189937}
2020-11-19 14:36:07,009 INFO  [ch.puz.qua.rea.bou.ReactiveDataConsumer] (vert.x-eventloop-thread-0) Received reactive message: {"data":0.27750984724271843}
```


## Solution

The needed resource files are available inside the folder [manifests/03.0/3.2/](https://github.com/puzzle/amm-techlab/tree/master/manifests/03.0/3.2/) of the techlab [github repository](https://github.com/puzzle/amm-techlab).

If you weren't successful, you can update your project with the solution by cloning the Techlab Repository `git clone https://github.com/puzzle/amm-techlab.git` and executing this command:

```s
oc apply -f manifests/03.0/3.2/
```
