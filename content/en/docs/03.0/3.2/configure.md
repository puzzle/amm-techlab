---
title: "3.2 Configure the application"
linkTitle: "3.2 Configure the application"
weight: 32
sectionnumber: 3.2
description: >
  Configure a Spring Boot application based on environment variables.
---

In this stage we show you how to configure your application by the environment.


## Task {{% param sectionnumber %}}.1: Check Project

For this lab the application of the previous lab is used.
Verify that you are in the right project `spring-boot-userXY`:

```bash
oc project
```

```
Using project "spring-boot-userXY" on server "https://api.techlab.openshift.ch:6443".
```


## Task {{% param sectionnumber %}}.2: Change Networking

We have to change a port on the service that we have created in the previous lab.


### Change service target port

Change the target port in the service `appuio-spring-boot-ex`. Note that we only have to change the target port in the service definition. For this case other existing services can still connect to the 8080 service port without any further changes.

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

We update the service using the `oc patch` command. This will update the resource directly in the project.

Change the port with following command:

```BASH
oc patch svc appuio-spring-boot-ex --type "json" -p '[{"op":"replace","path":"/spec/ports/0/targetPort","value":8081}]'
```

```
service/appuio-spring-boot-ex patched
```

Verify the changed port of the service with `oc describe`


```BASH
oc describe svc appuio-spring-boot-ex
```

```
{{< highlight YAML "hl_lines=8" >}}
Name:              appuio-spring-boot-ex
Namespace:         spring-boot-user14
Labels:            app=appuio-spring-boot-ex
Annotations:       <none>
Selector:          deployment=appuio-spring-boot-ex
Type:              ClusterIP
IP:                172.30.148.126
Port:              8080-tcp  8080/TCP
TargetPort:        8081/TCP
Endpoints:         10.130.4.24:8081
Port:              9000-tcp  9000/TCP
TargetPort:        9000/TCP
Endpoints:         10.130.4.24:9000
Session Affinity:  None
Events:            <none>
{{< / highlight >}}
```

With that change, the application is not reachable any more.


### Update exposed port of deployment

To fix the connection between the pod and the service, the pod port has to be changed too.

{{< highlight YAML "hl_lines=25" >}}
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
        resources: {}
{{< / highlight >}}

Update the HTTP Port from 8080 to 8081 using `oc patch` again:

```BASH
oc patch deployment appuio-spring-boot-ex --type "json" -p '[{"op":"replace","path":"/spec/template/spec/containers/0/ports/0/containerPort","value":8081}]'
```

```
deployment.apps/appuio-spring-boot-ex patched
```

Verify the changed port of the pod with `oc describe`


```BASH
oc describe deployment appuio-spring-boot-ex
```


## Task {{% param sectionnumber %}}.3: Configure application

There are several options how to configure a Java SpringBoot application. We'll show how to do it with environment variables. You can overwrite every property in the `application.properties` file with the corresponding environment variable. (eg. server.port=8081 in the application.properties is the same like SERVER_PORT=8081 as an environment variable)

The environment of the Deployment has to be changed with a new environment variable named SERVER_PORT.

{{< highlight YAML "hl_lines=29-31" >}}
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

First let's check the environment:

```BASH
oc set env deployment appuio-spring-boot-ex --list
```

```
# deployments/appuio-spring-boot-ex, container appuio-spring-boot-ex
```

There are no environment variables configured.

Add the environment variable `SERVER_PORT` with the value 8081:

```BASH
oc set env deployment appuio-spring-boot-ex SERVER_PORT=8081
```

```
deployment.apps/appuio-spring-boot-ex updated
```

The variable should be configured now.

```BASH
oc set env deployment appuio-spring-boot-ex --list
```

```
# deployments/appuio-spring-boot-ex, container appuio-spring-boot-ex
SERVER_PORT=8081
```


## Task {{% param sectionnumber %}}.4: Verify application

Changing the environment of a deployment triggers a rollout of the application pod.
After the container has started successfully, the application should be reachable again.

Check if the changes were applied correct. Open your browser and navigate to your application:
<https://appuio-spring-boot-ex-amm-userXY.ocp.aws.puzzle.ch/>


## Task {{% param sectionnumber %}}.5: Important notes

We showed how to change the OpenShift resources using the commands `oc patch` and `oc set env`.
This is good for developing or debugging the setup of an application project.

For changing stages and productive environments we propose updating the YAML representations inside the Git repository and apply the files again.
