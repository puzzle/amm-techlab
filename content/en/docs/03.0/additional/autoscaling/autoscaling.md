---
title: "3.3.2 Autoscaling"
linkTitle: "3.3.2 Autoscaling"
weight: 332
sectionnumber: 3.3.2
description: >
  Using the autoscaling feature of OpenShift.
---

In this example we will scale an automated application up and down, depending on how much load the application is under. For this we use an Ruby example webapp.

We first check that the project is ready for the lab.

Ensure that the `LAB_USER` environment variable is set.

```bash
echo $LAB_USER
```

If the result is empty, set the `LAB_USER` environment variable.

{{% details title="command hint" mode-switcher="normalexpertmode" %}}

```bash
export LAB_USER=<username>
```

{{% /details %}}

Create a new project to for the autoscale lab.

```bash
oc new-project ${LAB_USER}-autoscale
```

On the branch load there is a CPU intensive endpoint which we will use for our tests. Therefore we start the app on this branch:

```bash
oc new-app openshift/ruby:2.7-ubi8~https://github.com/chrira/ruby-ex.git#load
oc create route edge --insecure-policy=Allow --service=ruby-ex
```

{{% alert  color="primary" %}} Since [OpenShift 4.5](https://docs.openshift.com/container-platform/4.5/release_notes/ocp-4-5-release-notes.html#ocp-4-5-developer-experience) `oc new-app` creates a Deployment not a DeploymentConfig. {{% /alert %}}

Wait until the application is built and ready and the first metrics appear. You can follow the build as well as the existing pods. It will take a while until the first metrics appear, then the autoscaler will be able to work properly.

To see the metrics, go with the web-console to your OpenShift project (Developer view) and select the *Observe* menu item. Then change to the Metcis tab and select *CPU Usage* from the dropdown. If the metric has no datapoints, click the *Show PromQL* button and add following query:

```s
sum(node_namespace_pod_container:container_cpu_usage_seconds_total:sum_rate{namespace='<username>-autoscale'}) by (pod)
```

{{% alert  color="primary" %}}Replace **\<username>** with your username!{{% /alert %}}

Now we define a set of limits for our application that are valid for a single Pod:

```bash
oc edit deploy ruby-ex
```

We add the following resource limits to the container:

```yaml
        resources:
          limits:
            cpu: "0.2"
            memory: "256Mi"
```

The resources are originally empty: `resources: {}`. Attention the `resources` must be defined on the container and not on the deployment.

This will roll out our deployment again and enforce the limits.

As soon as our new container is running we can now configure the autoscaler:

```bash
oc autoscale deploy ruby-ex --min 1 --max 3 --cpu-percent=25
```

Now we can generate load on the service.

{{% alert  color="primary" %}} Use this command to get the Hostname of the route `oc get route -o custom-columns=NAME:.metadata.name,HOSTNAME:.spec.host` {{% /alert %}}

```bash
for i in {1..500}; do curl -s https://[HOSTNAME]/load ; done;
```

Every call to the load endpoint should respond with: `Extensive task done`

The current values we can get over:

```bash
oc get horizontalpodautoscaler.autoscaling/ruby-ex
```

Below we can follow our pods:

```bash
oc get pods -w
```

As soon as we finish the load the number of pods will be scaled down automatically after a certain time. However, the capacity is withheld for a while.
