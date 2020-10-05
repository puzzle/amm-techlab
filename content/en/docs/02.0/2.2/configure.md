---
title: "2.2 Configure the application"
linkTitle: "2.2 Configure the application"
weight: 22
sectionnumber: 2.2
description: >
  Configure the application based on environment variables.
---

In this stage, we show you how to configure your application.
For this lab the application of the previous lab is used.


## Task {{% param sectionnumber %}}.1: Change Networking

We have to change a port on the service that we have created in the previous lab.


### Change service target port

Change the target port in the service `data-producer`. Note that we only have to change the target port in the service definition. In this case, other existing services can still connect to the 8080 service port without any further changes.

```
{{< highlight YAML "hl_lines=13" >}}
apiVersion: v1
kind: Service
metadata:
  name: data-producer
  labels:
    application: amm-techlab
    app: data-producer
spec:
  ports:
  - name: 8080-tcp
    port: 8080
    protocol: TCP
    targetPort: 8081
  selector:
    deployment: data-producer
  sessionAffinity: None
  type: ClusterIP
{{< / highlight >}}
```

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/02.0/2.2/svc.yaml)

We update the service using the `oc patch` command. This will update the resource directly in the project.

Change the port with the following command:

```BASH
oc patch svc data-producer --type "json" -p '[{"op":"replace","path":"/spec/ports/0/targetPort","value":8081}]'
```

```
service/data-producer patched
```

Verify the changed port of the service with `oc describe`


```BASH
oc describe svc data-producer
```

```
{{< highlight YAML "hl_lines=9" >}}
Name:              data-producer
Namespace:         hanneloreXY
Labels:            application=amm-techlab
Annotations:       Selector:  deploymentConfig=data-producer
Type:              ClusterIP
IP:                172.30.118.194
Port:              8080-tcp  8080/TCP
TargetPort:        8081/TCP
Endpoints:         10.129.3.115:8081
Session Affinity:  None
Events:            <none>
{{< / highlight >}}
```

With that change, the application is not reachable any more.


### Update exposed port of deployment

To fix the connection between the pod and the service, the pod port has to be changed too.

{{< highlight YAML "hl_lines=28 38 46" >}}
apiVersion: v1
kind: DeploymentConfig
metadata:
  annotations:
    image.openshift.io/triggers: '[{"from":{"kind":"ImageStreamTag","name":"data-producer:rest"},"fieldPath":"spec.template.spec.containers[?(@.name==\"data-producer\")].image"}]'
  labels:
    application: amm-techlab
  name: data-producer
spec:
  replicas: 1
  selector:
    deploymentConfig: data-producer
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        application: amm-techlab
        deploymentConfig: data-producer
    spec:
      containers:
        - image: data-producer
          imagePullPolicy: Always
          livenessProbe:
            failureThreshold: 5
            httpGet:
              path: /health
              port: 8081
              scheme: HTTP
            initialDelaySeconds: 3
            periodSeconds: 20
            successThreshhold: 1
            timeoutSeconds: 15
          readinessProbe:
            failureThreshold: 5
            httpGet:
              path: /health
              port: 8081
              scheme: HTTP
            initialDelaySeconds: 3
            periodSeconds: 20
            successThreshold: 1
            timeoutSeconds: 15
          name: data-producer
          port:
            - containerPort: 8081
              name: http
              protocol: TCP
          resources:
            limits:
              cpu: "1"
              memory: 200Mi
            requests:
              cpu: 50m
              memory: 100Mi
  triggers:
    - imageChangeParams:
        automatic: true
        containerNames:
          - data-producer
        from:
          kind: ImageStreamTag
          name: data-producer:rest
      type: ImageChange
    - type: ConfigChange
{{< / highlight >}}

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/02.0/2.2/deploymentConfig.yaml)

Update the HTTP Port from 8080 to 8081 using `oc patch` again:
There are three ports to change. The container port itself, and the ports for the liveness/readiness probe.

```BASH
oc patch dc/data-producer --type "json" -p '[{"op":"replace","path":"/spec/template/spec/containers/0/ports/0/containerPort","value":8081}]'
oc patch dc/data-producer --type "json" -p '[{"op":"replace","path":"/spec/template/spec/containers/0/livenessProbe/httpGet/port","value":8081}]'
oc patch dc/data-producer --type "json" -p '[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/port","value":8081}]'

```

```
deploymentconfig.apps.openshift.io/data-producer patched
```

{{% alert title="Note" color="primary" %}} The changed DeploymentConfig should now represent the [solution](https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/02.0/2.2/deploymentConfig.yaml) {{% /alert %}}

Verify the changed port of the pod with `oc describe`

```BASH
oc describe deploymentconfig data-producer
```


## Task {{% param sectionnumber %}}.2: Configure application

There are several options how to configure a Quarkus application. We'll show how to do it with environment variables. You can overwrite every property in the `application.properties` file with the corresponding environment variable. (eg. `quarkus.http.port=8081` in the application.properties is the same like `QUARKUS_HTTP_PORT=8081` as an environment variable) [Quarkus: overriding-properties-at-runtime](https://quarkus.io/guides/config#overriding-properties-at-runtime)

The environment of the DeploymentConfig has to be extended with a new environment variable named `QUARKUS_HTTP_PORT`.

First, let's check the environment:

```BASH
oc set env dc/data-producer --list
```

```
# deploymentconfigs/data-producer, container data-producer
```

There are no environment variables configured.

Add the environment variable `QUARKUS_HTTP_PORT` with the value 8081:

```BASH
oc set env dc/data-producer QUARKUS_HTTP_PORT=8081
```

```
deploymentconfig.apps.openshift.io/data-producer updated
```

The variable should be configured now.

```BASH
oc set env dc/data-producer --list
```

```
# deploymentconfigs/data-producer, container data-producer
QUARKUS_HTTP_PORT=8081
```


## Task {{% param sectionnumber %}}.3: Verify application

Changing the environment of a deployment triggers a rollout of the application pod.
After the container has started successfully, the application should be reachable again.

Check if the changes were applied correctly. Open your browser and navigate to your application:  
<https://data-producer-amm-userXY.ocp.aws.puzzle.ch/data>

{{% alert  color="primary" %}}Replace **userXY** with your username!{{% /alert %}}


## Important notes

We showed how to change the OpenShift resources using the commands `oc patch` and `oc set env`.
This is good for developing or debugging the setup of an application project.

For changing stages and productive environments, we propose updating the YAML representations inside the Git repository and apply the files again.


## Solution

The needed resource files are available inside the folder *manifests/02.0/2.2/*.

If you weren't successful, you can update your project with the solution by executing this command:

```BASH
oc apply -f manifests/02.0/2.2/
```
