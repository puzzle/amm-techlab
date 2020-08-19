---
title: "3.2 Configure the application"
linkTitle: "Configure the application"
weight: 32
sectionnumber: 3.2
description: >
  Containerize an existing application.
---

## {{% param sectionnumber %}}.1 Configure application


In this stage we show you how to configure your application. There are several options how to configure an application, we will show how to do it with environment variables. You can overwrite every property in you `application.properties` file with the corresponding environment variable. (eg. server.port=8081 in the application.properties is the same like SERVER_PORT=8081 as an environment variable)


### Deployment

First open your `deployment.yaml` file and change the highlighted lines. Set the HTTP Port from 8080 to 8081 and add a new environment variable named SERVER_PORT.

{{< highlight YAML "hl_lines=25 29-31" >}}
apiVersion: apps/v1
kind: Deployment
metadata:
  annotations:
    image.openshift.io/triggers: '[{"from":{"kind":"ImageStreamTag","name":"appuio-spring-boot-ex:latest"},"fieldPath":"spec.template.spec.containers[?(@.name==\"appuio-spring-boot-ex\")].image"}]'
  labels:
    app: appuio-spring-boot-ex
  name: appuio-spring-boot-ex
spec:
  replicas: 1
  selector:
    matchLabels:
      deployment: appuio-spring-boot-ex
  template:
    metadata:
      creationTimestamp: null
      labels:
        deployment: appuio-spring-boot-ex
    spec:
      containers:
      - image: 'appuio-spring-boot-ex:latest'
        imagePullPolicy: IfNotPresent
        name: appuio-spring-boot-ex
        ports:
        - containerPort: 8081
          protocol: TCP
        - containerPort: 9000
          protocol: TCP
        env:
        - name: SERVER_PORT
          value: "8081"
        resources: {}
{{< / highlight >}}

Apply your changes with following command:

```BASH
oc apply -f deployment.yaml
```

```
//TODO: Add Output
```


### Service

Change the target port in `svc.yaml` to match the new configured port in the deployment. Note that we only have to change the target port in the service definition. For this case other existing services can still connect to the 8080 service port without any further changes.

```
{{< highlight YAML "hl_lines=11" >}}
apiVersion: v1
kind: Service
metadata:
  labels:
    app: appuio-spring-boot-ex
spec:
  ports:
  - name: 8080-tcp
    port: 8080
    protocol: TCP
    targetPort: 8081
  - name: 9000-tcp
    port: 9000
    protocol: TCP
    targetPort: 9000
  selector:
    deployment: appuio-spring-boot-ex
  sessionAffinity: None
  type: ClusterIP

{{< / highlight >}}
```

Apply your changes with following command:

```BASH
oc apply -f svc.yaml
```

```
//TODO: Add Output
```


### Verify

Check if the changes were applied correct. Open your browser and navigate to your application.
[https://appuio-spring-boot-ex-amm-userXY.ocp.aws.puzzle.ch/](https://appuio-spring-boot-ex-amm-userXY.ocp.aws.puzzle.ch/)

```
```
