---
title: "4.4 Image Deployment"
linkTitle: "Image Deployment"
weight: 440
sectionnumber: 4.4
description: >
  Container Image Deployment.
---


## {{% param sectionnumber %}}.1 Lab


## TODO Lab

* [ ] keine Buildconfig sondern direkt DeploymentConfig und ImageStream
* Beschreiben: Imagestream und polling / scheduling von neuen Images, damit image stream trigger funktioniert.
* Hinweis: per Default polling nur für latest Tag
* Beschreiben: Private Registry wie und wo muss man das pull secret angeben.


In this section we cover how to deploy an existing Docker Image from an image registry. Besides we show you create a ImageStream to track changes on the deployed image and trigger an update on the deployment.


There are three options for updating the ImageStreams


Let's start with the deployment configuration

```YAML
apiVersion: apps.openshift.io/v1
kind: DeploymentConfig
metadata:
  name: appuio-spring-boot
spec:
  replicas: 1
  selector:
    name: appuio-spring-boot
  template:
    metadata:
      labels:
        name: appuio-spring-boot
    spec:
      containers:
      - image: 'appuio-spring-boot:latest'
        imagePullPolicy: IfNotPresent
        name: appuio-spring-boot
        ports:
        - containerPort: 8080
          protocol: TCP
        - containerPort: 9000
          protocol: TCP
  triggers:
  - type: ConfigChange
  - imageChangeParams:
      automatic: true
      containerNames:
      - appuio-spring-boot
      from:
        kind: ImageStreamTag
        name: appuio-spring-boot:latest
    type: ImageChange  
  strategy:
    type: Rolling  
```

Next we create the ImageStream definition. The important part is under the `tag` section. There we define a reference to an external Docker registry and define the image.

```YAML
apiVersion: image.openshift.io/v1
kind: ImageStream
metadata:
  labels:
    app: appuio-spring-boot
  name: appuio-spring-boot
spec:
  lookupPolicy:
    local: false
  tags:
  - from:
      kind: DockerImage
      name: appuio/example-spring-boot
    name: latest
    importPolicy:
      scheduled: true
    referencePolicy:
      type: Source
```
