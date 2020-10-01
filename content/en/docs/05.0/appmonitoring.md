---
title: "5.1 Application Monitoring"
linkTitle: "5.1 Application Monitoring"
weight: 510
sectionnumber: 5.1
description: >
  Application Monitoring with Prometheus und Grafana
---

## Collecting Application Metrics

When running application in production a fast feedback loop is absolute key. The following reasons show why it's essential to gather and combine all sorts of metrics, when running an application in production:

* To make sure that an application runs smoothly
* To be able to see production issues and send alerts
* to debug an application
* to take business and architectural decisions
* metrics can also help to decide on how to scale applications

Application Metrics provide insights into what is happening inside our Quarkus Applications using the [MicroProfile Metrics](https://github.com/eclipse/microprofile-metrics) specification.

Those Metrics (e.g. Request Count on a specific URL) are collected within the application and then can be processed with tools like Prometheus for further analysis and visualisation.

[Prometheus](https://prometheus.io/) is a monitoring system and timeseries database which integrates great with all sorts of applications and platforms.

The basic principle behind Prometheus is to collect metrics using a polling mechanism. There are a lot of different so called [exporters](https://prometheus.io/docs/instrumenting/exporters/#exporters-and-integrations), where metrics can be collected from.

In our case the metrics will be collected from a specific path provided by the application (`/metrics`)


## Architecture

On our lab cluster a Prometheus / Grafana stack is already deployed. Using the service discovery capability of the prometheus - kubernetes integration the running Prometheus server will be able locate our application almost out of the box.

* Prometheus running in the namespace `pitc-infra-monitoring`
* Prometheus must be able to collect Metrics from the running application, by sending GET Requests (Network Policy)
* Prometheus must know where to go an collect the metrics from


## Annotation vs. Service Monitor

Earlier Prometheus - Kubernetes integrations worked by annotating Kubernetes Resources with specific information configured. Which helped the Prometheus Server to find the endpoints to collect Metrics from.

```yaml
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/scheme: http
    prometheus.io/port: "8080"
```

The current OpenShift - Prometheus integration works differently and is a lot more flexible. It is based on the ServiceMonitor CustomResource.

```bash
oc explain ServiceMonitor
# Or
oc describe crd ServiceMonitor
```


## Task {{% param sectionnumber %}}.1: Create Service Monitor

Let's now create our first ServiceMonitor, switch back to the project of lab 3

```bash
oc project <namespace>
```

Create the following ServiceMonitor resource as local file `<workspace>/servicemonitor-consumer.yaml` and make sure to replace the `<namespace>` with your project name.
```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  labels:
    k8s-app: quarkus-techlab-monitor
  name: consumer-monitor
spec:
  endpoints:
  - interval: 30s
    port: data-consumer-http
    scheme: http
    path: /metrics
  namespaceSelector:
    matchNames:
      - <namespace>
  selector:
    matchLabels:
      application: quarkus-techlab
```

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/05.0/5.1/servicemonitor-consumer.yaml)

Create the build config.

```BASH
oc apply -f servicemonitor-consumer.yaml
```

Expected result: `servicemonitor.monitoring.coreos.com/consumer-monitor created`

{{% alert title="Warning" color="secondary" %}}
Your current user must have the following rights in the current namespace: `oc policy add-role-to-user monitoring-edit <user> -n <namespace>`
Tell your trainer if you get a permission error while creating the ServiceMonitor
{{% /alert %}}


## Task {{% param sectionnumber %}}.2: Verify whether the Prometheus Targets gets scraped or not

Prometheus is integrated into the OpenShift Console under the Menu Item Monitoring.
But as part of this lab, we want to use grafana to interact with prometheus.
Open Grafana (URL provided by the trainer) and switch to the explore tab, then execute the following query to check whether your target is configured or not:

{{% alert title="Note" color="primary" %}}
Make sure to replace `<namespace>` with your current namespace
{{% /alert %}}

<!-- Didn't work had no data showing -->
```
prometheus_sd_discovered_targets{config="<namespace>/consumer-monitor/0"}
```


## Task {{% param sectionnumber %}}.3: Create Service Monitor for the Producer Service

Similar to Task {{% param sectionnumber %}}.1 create a ServiceMonitor or alter the current one to add metrics from the producer Service


## Task {{% param sectionnumber %}}.4: Query Application Metrics

Since the Metrics are now collected from both services, let's execute a query and visualise the data.

for example the total seconds the Garbage Collector ran

```
sum(base_gc_time_total_seconds{namespace="<namespace>-eventdriven"})
```
