---
title: "5.2 Tracing"
linkTitle: "5.2 Tracing"
weight: 520
sectionnumber: 5.2
description: >
  Tracing in a Microservices Architecture
---

## Tracing

When it comes to large distributed cloud native system with many different components involved, debugging production issues or even finding a way to display how components interact with each other becomes quite hard and tricky.

This is where tracing comes into the picture. Tracing allows us to collect all sorts of requests in a group of requests, which somehow belong together to a single business transaction.
In our Quarkus applications, we use [Eclipse MicroProfile OpenTracing](https://github.com/eclipse/microprofile-opentracing/blob/master/spec/src/main/asciidoc/microprofile-opentracing.asciidoc) to collect the tracing data and [Jaeger](https://www.jaegertracing.io/) as a component where those traces are sent to and been visualised for further analysis.


## Task {{% param sectionnumber %}}.1: Check project setup

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

> Don't forget to deploy/update your resources with the git instead of the oc command for this lab


## Task {{% param sectionnumber %}}.2: Deploy Jaeger instance

Then let's quickly deploy a Jaeger instance.

{{% alert title="Note" color="primary" %}}
This Jaeger deployment is not meant for production use! Data is only stored in memory. In a production environment, there would probably be one Jaeger instance used by multiple Services.
{{% /alert %}}


Create the local file `<workspace>/jaeger.yaml` with the following content:

{{< highlight yaml >}}{{< readfile file="manifests/05.0/5.2/jaeger.yaml" >}}{{< /highlight >}}

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/05.0/5.2/jaeger.yaml)


Let ArgoCD manage the resources by adding the file to git and push it.

<details><summary>command hint</summary>

```bash
git add jaeger.yaml && git commit -m "Add Jaeger Manifest" && git push
```

</details><br/>

Wait for ArgoCD to deploy the Jaeger instance or do it manually by applying the file.

<details><summary>command hint</summary>

```bash
oc apply -f jaeger.yaml
```

Expected result:

```
jaeger.jaegertracing.io/jaeger-all-in-one-inmemory created
```

</details><br/>

Verify the deployment

```bash
oc get pod -w
```

{{% alert  color="primary" %}}Press `Ctrl+C` to stop the watching of the pods.{{% /alert %}}

The newly deployed Jaeger instance is also available over a route.

```bash
oc get route jaeger-all-in-one-inmemory --template={{.spec.host}}
```

```
jaeger-all-in-one-inmemory-<username>.{{% param techlabClusterDomainName %}}
```

Use this URL with https protocol to open the Jaeger web console in a Browser window. Use your techlab user credentials to log in. Ensure to allow the proposed permissions.


## Task {{% param sectionnumber %}}.3: Send Traces to Jaeger

Now let's make sure the traces that are collected within our microservices are also been sent to the running Jaeger services.


To achieve that, we need to deploy a different version of our microservices. Update the deployment config (`producer.yaml`) to use the jaeger feature:

```
    spec:
      containers:
        - image: quay.io/puzzle/quarkus-techlab-data-producer:jaegerkafka
          imagePullPolicy: Always
          env:
            - name: QUARKUS_JAEGER_ENABLED
              value: 'true'
          livenessProbe:
            failureThreshold: 5
```

Update your resources and apply the changes.

<details><summary>command hint</summary>

```bash
git add . && git commit -m "Enable jaeger feature on producer" && git push
```

</details><br/>

Next we configure the consumer to use the jaeger feature. To enable jaeger, open `<workspace>/consumerConfigMap.yaml` and change the `quarkus.jaeger.enabled` property.

```
{{< highlight YAML "hl_lines=10" >}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: consumer-config
data:
  # Configure the SmallRye Kafka connector
  kafka.bootstrap.servers: 'amm-techlab-kafka-bootstrap:9092'

  #Toggle jaeger trace feature
  quarkus.jaeger.enabled: 'true'
  
  # Configure the Kafka sink
  mp.messaging.incoming.data.connector: smallrye-kafka
  mp.messaging.incoming.data.topic: manual
  mp.messaging.incoming.data.value.deserializer: ch.puzzle.quarkustechlab.reactiveconsumer.control.SensorMeasurementDeserializer
{{< / highlight >}}
```

Update your resources and apply the changes.

<details><summary>command hint</summary>

```bash
git add . && git commit -m "Enable jaeger feature on consumer" && git push
```

</details><br/>


And also reconfigure the environment of the data-transformer (`<workspace>/data-transformer.yaml`) to enable Jaeger by changing the `quarkus.jaeger.enabled` env to `true`

```yaml
...
env:
...
- name: quarkus.jaeger.enabled
  value: 'true'
```

<details><summary>command hint</summary>

```bash
`git add . && git commit -m "Enable jaeger feature on transformer" && git push`
```

</details><br/>


## Task {{% param sectionnumber %}}.4: Explore the Traces

Explore the Traces in the Jaeger Console once again. You should see the data-producer and data-consumer as services.
