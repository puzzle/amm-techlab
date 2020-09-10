---
title: "2.1 Containerize an existing application"
linkTitle: "2.1 Containerize an existing application"
weight: 21
sectionnumber: 2.1
description: >
  Containerize an existing application.
---

The main goal of this lab is to show you how to containerize an existing Java application. Including deployment on OpenShift and exposing the service with a route.


## Task {{% param sectionnumber %}}.1: Setup Project

Prepare a new OpenShift project

```bash
oc new-project spring-boot-userXY
```


## Task {{% param sectionnumber %}}.2: Inspect Dockerfile

First we need a Dockerfile. You can find the `Dockerfile` in the root directory of the example Java application
[Git Repository](https://gitea.techlab.openshift.ch/APPUiO-AMM-Techlab/example-spring-boot-helloworld).
The base image is a `fabric8/java-centos-openjdk11-jdk` which is pre configured for Java builds.


```Dockerfile
FROM fabric8/java-centos-openjdk11-jdk

LABEL maintainer="philipona@puzzle.ch"

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

[source](https://gitea.techlab.openshift.ch/APPUiO-AMM-Techlab/example-spring-boot-helloworld/raw/branch/master/Dockerfile)


This Dockerfile is responsible for building the Java application. For this we use the UBI Docker image. This image is pre configured to build and run Java applications.
To build the Java Spring Boot application, the `Dockerfile` uses the [Gradle Wrapper](https://docs.gradle.org/current/userguide/gradle_wrapper.html).


## Task {{% param sectionnumber %}}.3: Create BuildConfig

The [BuildConfig](https://docs.openshift.com/container-platform/4.5/builds/understanding-buildconfigs.html) describes how a single build task is performed. The BuildConfig is primary characterized by the Build strategy and its resources. For our build we use the Docker strategy. (Other strategies will be discussed in Chapter 4) The Docker strategy invokes the Docker build command. Furthermore it expects a `Dockerfile` in the source repository.
Beside we configure the source and the triggers as well. For the source we can specify any Git repository. This is where the application sources resides. The triggers describe how to trigger the build. In this example we provide four different triggers. (Generic webhook, GitHub webhook, ConfigMap change, Image change)

It is a good practice to use [Red Hat Universal Base Images](https://developers.redhat.com/products/rhel/ubi).
With the BuildConfig of OpenShift we can overwrite the base image of a Dockerfile (FROM directive).
See the highlighted line of the following BuildConfig, where we define a new base image.
The image ([registry.access.redhat.com/ubi8/openjdk-11](https://catalog.redhat.com/software/containers/ubi8/openjdk-11/5dd6a4b45a13461646f677f4)) is referenced by the image stream `openjdk-11`.

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
      uri: https://gitea.techlab.openshift.ch/APPUiO-AMM-Techlab/example-spring-boot-helloworld
    type: Git
  strategy:
    dockerStrategy:
      from:
        kind: ImageStreamTag
        name: openjdk-11:latest
    type: Docker
  resources:
    limits:
      cpu: "500m"
      memory: "2G"
    requests:
      cpu: "250m"
      memory: "1G"
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

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/content/en/docs/02.0/2.1/buildConfig.yaml)

Create the build config.

```BASH
oc create -f https://raw.githubusercontent.com/puzzle/amm-techlab/master/content/en/docs/02.0/2.1/buildConfig.yaml
```

```
buildconfig.build.openshift.io/appuio-spring-boot-ex created
```


## Task {{% param sectionnumber %}}.4: Create ImageStreams

Next we need to configure an [ImageStream](https://docs.openshift.com/container-platform/4.5/openshift_images/image-streams-manage.html) for the Java base image (ubi8/openjdk-11) and our application image (appuio-spring-boot-ex). The ImageStream is an abstraction for referencing images from within OpenShift Container Platform. Simplified the ImageStream tracks changes for the defined images and reacts by triggering a new Build.

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
  name: openjdk-11
spec:
  lookupPolicy:
    local: false
  tags:
  - annotations:
      openshift.io/imported-from: registry.access.redhat.com/ubi8/openjdk-11
    from:
      kind: DockerImage
      name: registry.access.redhat.com/ubi8/openjdk-11
    importPolicy: {}
    name: latest
    referencePolicy:
      type: Source
```

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/content/en/docs/02.0/2.1/imageStreams.yaml)

Let's create the ImageStreams

```BASH
oc create -f https://raw.githubusercontent.com/puzzle/amm-techlab/master/content/en/docs/02.0/2.1/imageStreams.yaml
```

```
imagestream.image.openshift.io/appuio-spring-boot-ex created
imagestream.image.openshift.io/openjdk-11 created
```


## Task {{% param sectionnumber %}}.5: Deploy Application

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

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/content/en/docs/02.0/2.1/deployment.yaml)

Let's create the deployment with following command

```BASH
oc create -f https://raw.githubusercontent.com/puzzle/amm-techlab/master/content/en/docs/02.0/2.1/deployment.yaml
```

```
deployment/appuio-spring-boot-ex created
```

When you check your project in the web console (Developer view) the example app is visible.
The pod will be deployed successfully when the build finishes and the application image is pushed to the image stream. Please note this might take several minutes.


## Task {{% param sectionnumber %}}.6: Create Service

Expose the container ports to the to the cluster with a Service. For the Service we configure two different ports. `8080` for the Web API, `9000` for the metrics and health check. We set the Service type to ClusterIP to expose the Service cluster internal only.

```YAML
apiVersion: v1
kind: Service
metadata:
  name: appuio-spring-boot-ex
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

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/content/en/docs/02.0/2.1/svc.yaml)

Create the Service in OpenShift

```bash
oc create -f https://raw.githubusercontent.com/puzzle/amm-techlab/master/content/en/docs/02.0/2.1/svc.yaml
```

```
service/appuio-spring-boot-ex created
```


## Task {{% param sectionnumber %}}.7: Create Route

Create a Route to expose the service at a host name. This will make the application available outside of the cluster.

The TLS type is set to Edge. That will configure the router to terminate the SSL connection and forward to the service with HTTP.

```YAML
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  labels:
    app: appuio-spring-boot-ex
  name: appuio-spring-boot-ex
spec:
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

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/content/en/docs/02.0/2.1/route.yaml)


Create the Route in OpenShift

```bash
oc create -f https://raw.githubusercontent.com/puzzle/amm-techlab/master/content/en/docs/02.0/2.1/route.yaml
```

```
route.route.openshift.io/appuio-spring-boot-ex created
```


## Task {{% param sectionnumber %}}.8: Verify deployed resources

Now we can list all resources in our project to double check if everything is up und running.
Use the following command to display all resources within our project.

```BASH
oc get all
```

```
{{< highlight text "hl_lines=9 22" >}}
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
imagestream.image.openshift.io/appuio-spring-boot-ex       image-registry.openshift-image-registry.svc:5000/spring-boot-userXY/appuio-spring-boot-ex       latest   22 hours ago
imagestream.image.openshift.io/openjdk-11   image-registry.openshift-image-registry.svc:5000/spring-boot-userXY/openjdk-11   latest   23 hours ago

NAME                                             HOST/PORT                                                PATH   SERVICES                PORT       TERMINATION   WILDCARD
route.route.openshift.io/appuio-spring-boot-ex   appuio-spring-boot-ex-spring-boot-userXY.ocp.aws.puzzle.ch          appuio-spring-boot-ex   8080-tcp   edge          None

{{< / highlight >}}
```


## Task {{% param sectionnumber %}}.9: Access application by browser

Finally you can visit your application with the URL provided from the Route: <https://appuio-spring-boot-ex-spring-boot-userXY.techlab.openshift.ch/>

> Replace `userXY with your username or get the url from your route.
