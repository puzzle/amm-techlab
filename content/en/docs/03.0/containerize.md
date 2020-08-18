---
title: "3.1 Containerize an existing application"
linkTitle: "Containerize an existing application"
weight: 31
sectionnumber: 3.1
description: >
  Containerize an existing application.
---


## Containerize an existing application


The main goal of this lab is to show you how to containerize an existing Java application. Including deployment on OpenShift and exposing the service with a route.


{{% alert title="Note" color="primary" %}}
Replace `userXY` with your username.
{{% /alert %}}

### Setup Project

Prepare a new OpenShift project

```bash
oc new-project spring-boot-userXY
```


### Dockerfile

First we need a Dockerfile. You can find the `Dockerfile` in the root directory of the example Java application.
As base image we use the `fabric8/java-centos-openjdk11-jdk` which is pre configured for Java builds.


```Dockerfile
FROM fabric8/java-centos-openjdk11-jdk

MAINTAINER Thomas Philipona <philipona@puzzle.ch>

EXPOSE 8080 9000


LABEL io.k8s.description="Example Spring Boot App" \
      io.k8s.display-name="APPUiO Spring Boot App" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="builder,springboot"

RUN mkdir -p /tmp/src/
ADD . /tmp/src/

RUN cd /tmp/src && sh gradlew build -Dorg.gradle.daemon=false

RUN cp -a  /tmp/src/build/libs/springboots2idemo*.jar /deployments/springboots2idemo.jar
```

This Dockerfile is responsible for building the Java application. For this we use the fabric8 Docker image. This image is pre configured to build and run Java applications.
To build the Java Spring Boot application, the `Dockerfile` make us of the [Gradle Wrapper](https://docs.gradle.org/current/userguide/gradle_wrapper.html).

- [ ] Erklärung was genau passiert
- [ ] Ressourcen Schritt für Schritt anwenden, anschliessend Zeigen wie.
- [ ] Optional: Webhook (oder verlinkung)


### BuildConfig

Create a new file called `buildConfig.yaml` for the BuildConfig.
The [BuildConfig](https://docs.openshift.com/container-platform/4.5/builds/understanding-buildconfigs.html) describes how a single build task is performed. The BuildConfig is primary characterized by the Build Strategy and its resources. For out build we use the Docker Strategy. The Docker Strategy invokes the docker build command. Furthermore it expects a `Dockerfile` in the source repository.
Beside we configure the source and the triggers as well. For the source we can specify any Git repository. This is where the application sources reside. The triggers describe how to trigger the build. In this example we provide four different triggers. (Generic webhook, GitHub webhook, ConfigMap change, Image change)

```YAML
apiVersion: build.openshift.io/v1
kind: BuildConfig
metadata:
  labels:
    app: appuio-spring-boot-ex
  name: appuio-spring-boot-ex
spec:
  completionDeadlineSeconds: 1800
  failedBuildsHistoryLimit: 5
  output:
    to:
      kind: ImageStreamTag
      name: appuio-spring-boot-ex:latest
  runPolicy: Serial
  source:
    git:
      uri: https://github.com/userXY/example-spring-boot-helloworld
    type: Git
  strategy:
    dockerStrategy:
      from:
        kind: ImageStreamTag
        name: java-centos-openjdk11-jdk:latest
    type: Docker
  resources:
    limits:
      cpu: "500m"
      memory: "2Gb"
    requests:
      cpu: "250m"
      memory: "1Gb"
  triggers:
  - github:
      secret: soV621heA_1fUIh4tXvK
    type: GitHub
  - generic:
      secret: nQT4ROYzckEUOmLnqHTX
    type: Generic
  - type: ConfigChange
  - imageChange: {}
    type: ImageChange


```

Create the build config.
```BASH
oc create -f buildConfig.yaml
```

```
buildconfig.build.openshift.io/appuio-spring-boot-ex created
```


### ImageStreams

Next we need to configure an [ImageStream](https://docs.openshift.com/container-platform/4.5/openshift_images/image-streams-manage.html) for the Java base image (java-centos-openjdk11-jdk) and our application image (appuio-spring-boot-ex). Create a new file called `imageStreams.yaml`. The ImageStream is an abstraction for referencing images from within OpenShift Container Platform. Simplified the ImageStream tracks changes for the defined images and reacts by performing a new Build.

```YAML
apiVersion: image.openshift.io/v1
kind: ImageStream
metadata:
  labels:
    app: appuio-spring-boot-ex
  name: appuio-spring-boot-ex
spec:
  lookupPolicy:
    local: false
---
apiVersion: image.openshift.io/v1
kind: ImageStream
metadata:
  labels:
    app: appuio-spring-boot-ex
  name: java-centos-openjdk11-jdk
spec:
  lookupPolicy:
    local: false
  tags:
  - annotations:
      openshift.io/imported-from: fabric8/java-centos-openjdk11-jdk
    from:
      kind: DockerImage
      name: fabric8/java-centos-openjdk11-jdk
    importPolicy: {}
    name: latest
    referencePolicy:
      type: Source
```

Create the ImageStreams

```BASH
oc create -f imageStreams.yaml
```

```
imagestream.image.openshift.io/appuio-spring-boot-ex created
imagestream.image.openshift.io/java-centos-openjdk11-jdk created

```

### Deployment

After the ImageStream definition we can setup our Deployment. Please note the Deployment annotation `image.openshift.io/triggers`, this annotation connects the Deployment with the ImageStreamTag (which is automatically created by the ImageSource object)

```YAML
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
        - containerPort: 8080
          protocol: TCP
        - containerPort: 9000
          protocol: TCP
        resources: {}
```


### Service

Expose the Service to the cluster with a Service. First create a new file named `svc.yaml`. For the Service we configure two different ports. 8000 for the Web API, 9000 for the metrics. We set the Service type to ClusterIP to expose the Service cluster internal only.

```YAML
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
    targetPort: 8080
  - name: 9000-tcp
    port: 9000
    protocol: TCP
    targetPort: 9000
  selector:
    deployment: appuio-spring-boot-ex
  sessionAffinity: None
  type: ClusterIP

```

Create the Service in OpenShift

```bash
oc create -f svc.yaml
```

```
service/appuio-spring-boot-ex created
```


### Route

Create a Route to expose the service at a host name. The TLS type is set to Edge

```YAML
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  labels:
    app: appuio-spring-boot-ex
  name: appuio-spring-boot-ex
spec:
  host: appuio-spring-boot-ex-<PROJECT_NAME>.ocp.aws.puzzle.ch
  port:
    targetPort: 8080-tcp
  to:
    kind: Service
    name: appuio-spring-boot-ex
    weight: 100
  tls:
    termination: edge
  wildcardPolicy: None
``` 

Create the Route in OpenShift

```bash
oc create -f route.yaml
```

```
route.route.openshift.io/appuio-spring-boot-ex created
```

### Verify

No we can list all resources in our project to double check if everything is up und running.

```BASH
oc get all
```

```
NAME                                         READY   STATUS      RESTARTS   AGE
pod/appuio-spring-boot-ex-1-build            0/1     Completed   0          22h
pod/appuio-spring-boot-ex-589c4f8855-cm9n6   1/1     Running     0          21h

NAME                            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE
service/appuio-spring-boot-ex   ClusterIP   172.30.236.178   <none>        8080/TCP,9000/TCP   22h

NAME                                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/appuio-spring-boot-ex   1/1     1            1           22h

NAME                                               DESIRED   CURRENT   READY   AGE
replicaset.apps/appuio-spring-boot-ex-589c4f8855   1         1         1       21h
replicaset.apps/appuio-spring-boot-ex-598c8bb597   0         0         0       21h
replicaset.apps/appuio-spring-boot-ex-59b5447f8f   0         0         0       21h
replicaset.apps/appuio-spring-boot-ex-74c797b9d    0         0         0       22h
replicaset.apps/appuio-spring-boot-ex-84bc88878c   0         0         0       22h

NAME                                                   TYPE     FROM   LATEST
buildconfig.build.openshift.io/appuio-spring-boot-ex   Docker   Git    2

NAME                                               TYPE     FROM          STATUS     STARTED        DURATION
build.build.openshift.io/appuio-spring-boot-ex-1   Docker   Git@5f65829   Complete   23 hours ago   7m12s

NAME                                                       IMAGE REPOSITORY                                                                            TAGS     UPDATED
imagestream.image.openshift.io/appuio-spring-boot-ex       image-registry.openshift-image-registry.svc:5000/amm-cschlatter/appuio-spring-boot-ex       latest   22 hours ago
imagestream.image.openshift.io/java-centos-openjdk11-jdk   image-registry.openshift-image-registry.svc:5000/amm-cschlatter/java-centos-openjdk11-jdk   latest   23 hours ago

NAME                                             HOST/PORT                                                PATH   SERVICES                PORT       TERMINATION   WILDCARD
route.route.openshift.io/appuio-spring-boot-ex   appuio-spring-boot-ex-amm-cschlatter.ocp.aws.puzzle.ch          appuio-spring-boot-ex   8080-tcp   edge          None

```


### Update source code

Go to your GitHub repo and modify anything in the index.html file. Commit and push your changes back to your repository. Then switch back to the OpenShift Web GUI and trigger a new build including the modified source code. Click on `Builds` in the left Menu. Select your `appuio-spring-boot-ex` and open the `Actions` menu in the top right corner, then select `Start Build`. As soon the build starts, you can see the Build details. After the Build is finished, the ImageSource detects changes in the Image repository and updates the corresponding ImageStreamTag.


### Configure application

In this stage we show you how to configure your application. There are several options how to configure an application, we will show how to do it with environment variables. You can overwrite every property in you `application.properties` file with the corresponding environment variable. (eg. server.port=8081 in the application.properties is the same like SERVER_PORT=8081 as an environment variable)

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

Change the target port in `svc.yaml` to match the new configured port in the deployment
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
