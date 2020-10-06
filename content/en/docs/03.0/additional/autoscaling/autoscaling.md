---
title: "3.3.2 Autoscaling"
linkTitle: "3.3.2 Autoscaling"
weight: 332
sectionnumber: 3.3.2
description: >
  Using the autoscaling feature of OpenShift.
---

In this example we will scale an automated application up and down, depending on how much load the application is under. For this we use our old Ruby example webapp.

```bash
oc new-project autoscale-userXY
```

On the branch load there is a CPU intensive endpoint which we will use for our tests. Therefore we start the app on this branch:

```bash
oc new-app openshift/ruby:2.5~https://git.apps.cluster-centris-0c77.centris-0c77.example.opentlc.com/training/ruby-ex.git#load
oc create route edge --insecure-policy=Allow --service=ruby-ex
```

Wait until the application is built and ready and the first metrics appear. You can follow the build as well as the existing pods.

It will take a while until the first metrics appear, then the autoscaler will be able to work properly.

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

**Note** Use this command to get the Hostname of the route
`oc get route -o custom-columns=NAME:.metadata.name,HOSTNAME:.spec.host`

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
