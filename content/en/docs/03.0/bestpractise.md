---
title: "3.3 Best practices"
linkTitle: "Best practices"
weight: 33
sectionnumber: 3.3
description: >
  Best practices for creating OpenShift containers.
---
## TODO


## Best practices for container in general


### Instructions order

//TODO


## Best practices for creating OpenShift containers


### Root Users

Container Images which running under root user, are not permitted in OpenShift clusters.


### Random User IDs

Unlike Kubernetes, OpenShift uses arbitrary User IDs.


### File permissions

//TODO


### Health checks (Readiness and liveness probe)
