---
title: "4.2 Binary Deployment"
linkTitle: "Binary Deployment"
weight: 420
sectionnumber: 4.2
description: >
  Building images from binary using Binary Build.
---


## {{% param sectionnumber %}}.1 Lab


## TODO Lab

* [ ] Build Config erstellen, Binary Deployment
* [ ] oc new-build mit from file, das artefakt ist ein Jar file, das von github herunter geladen werden kann, direkt integriert in den Lab Dokumenten.
* [ ] DeploymentConfig, Service, Route auch noch via oc apply erstellen und dann entsprechend die App aufrufen
* [ ] Hinweis eigenes Build Image verwenden, falls in ext. privater Registry -> Proxy Einstellungen


> Binary builds require content from the local file system. Therefore automatic triggering a build is not possible.


### Uses cases of binary builds

* Build and test code local
* Bypass the SCM
* Build images with artifacts from different sources


### BuildConfig

Let's create a BuildConfig for our binary deployment


```YAML
apiVersion: build.openshift.io/v1
kind: BuildConfig
metadata:
  labels:
    build: spring-boot-bb
  name: spring-boot-bb
spec:
  failedBuildsHistoryLimit: 5
  nodeSelector: null
  output:
    to:
      kind: ImageStreamTag
      name: spring-boot-bb:latest
  postCommit: {}
  resources: {}
  runPolicy: Serial
  source:
    binary: {}
    type: Binary
  strategy:
    dockerStrategy: {}
    type: Docker
  successfulBuildsHistoryLimit: 5
  triggers:
  - github:
      secret: yRLxbxn-mMOUJxxUOf00
    type: GitHub
  - generic:
      secret: 8H7gL3nIr5C7QyKuqrQO
    type: Generic
```


Next, we trigger our build from the CLI. Navigate into the spring-boot directory

```BASH
cd spring-boot.......
```

```BASH
oc start-build spring-boot-bb --from-dir="."
```

You see the following output

```
Uploading directory "." as binary input for the build ...

Uploading finished
build.build.openshift.io/spring-boot-bb-1 started
```

