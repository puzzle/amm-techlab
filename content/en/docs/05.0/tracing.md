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


## Task {{% param sectionnumber %}}.1: Deploy Jaeger instance

Make sure to currently be in your main project (lab 3) where your application and other services are deployed:

```bash
oc project <userXY>
```

Then let's quickly deploy a Jaeger instance.

{{% alert title="Note" color="primary" %}}
This Jaeger deployment is not meant for production use! Data is only stored in memory. In a production environment, there would probably be one Jaeger instance used by multiple Services.
{{% /alert %}}


Create the local file `<workspace>/jaeger.yaml` with the following content:

```yaml
apiVersion: jaegertracing.io/v1
kind: Jaeger
metadata:
  name: jaeger-all-in-one-inmemory
```

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/05.0/5.2/jaeger.yaml)

And then execute the following command:

```bash
oc apply -f jaeger.yaml

```

Expected result:

```bash
jaeger.jaegertracing.io/jaeger-all-in-one-inmemory created
```

Verify the deployment

```bash
oc get pod -w
```

The newly deployed Jaeger instance is also available over a route.

```bash
oc get route jaeger-all-in-one-inmemory
```

```bash
NAME                         HOST/PORT                                                                 PATH   SERVICES                           PORT    TERMINATION   WILDCARD
jaeger-all-in-one-inmemory   jaeger-all-in-one-inmemory-<namespace>.techlab.openshift.ch                      jaeger-all-in-one-inmemory-query   <all>   reencrypt     None
```

Open the Jaeger web console in a Browserwindow and login with your credentials


## Task {{% param sectionnumber %}}.2: Send Traces to Jaeger

Now let's make sure the traces that are collected within our microservices are also been sent to the running Jaeger services.

To achieve that, we need to deploy a different version of our microservices. Update the deployment config (`consumer.yaml` and `deploymentConfig.yaml`) to use the new images:

```
puzzle/quarkus-techlab-data-consumer:jaegerkafka
puzzle/quarkus-techlab-data-producer:jaegerkafka
```


Update your resources and apply the changes running the following command

```bash
oc apply -f consumer.yaml
oc apply -f deploymentConfig.yaml
```


## Task {{% param sectionnumber %}}.3: Explore the Traces

Explore the Traces in the Jaeger Console once again.
