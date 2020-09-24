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
oc new-project producer-consumer-userXY
```


## Task {{% param sectionnumber %}}.2: Inspect Dockerfile

First we need a Dockerfile. You can find the `Dockerfile` in the root directory of the example Java application
[Git Repository](https://gitea.techlab.openshift.ch/APPUiO-AMM-Techlab/example-spring-boot-helloworld).
The base image is a `fabric8/java-centos-openjdk11-jdk` which is pre configured for Java builds.


```Dockerfile

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
  annotations:
    openshift.io/generated-by: OpenShiftNewBuild
  labels:
    build: data-producer
    application: amm-techlab
  name: data-producer-docker
spec:
  output:
    to:
      kind: ImageStreamTag
      name: data-producer:latest
  postCommit: {}
  resources:
    limits:
      cpu: "500m"
      memory: "512Mi"
    requests:
      cpu: "250m"
      memory: "512Mi"
  source:
    git:
      uri: https://github.com/g1raffi/quarkus-techlab-data-consumer.git
      ref: rest
    type: Git
  strategy:
    dockerStrategy:
      dockerfilePath: src/main/docker/Dockerfile.multistage
    type: Docker
  triggers:
  - github:
      secret: PPMUkybOXqfoY_bJd-ou
    type: GitHub
  - generic:
      secret: f31PWzHXBGI9iYw-fTli
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
buildconfig.build.openshift.io/data-producer created
```


## Task {{% param sectionnumber %}}.4: Create ImageStreams

Next we need to configure an [ImageStream](https://docs.openshift.com/container-platform/4.5/openshift_images/image-streams-manage.html) for the Java base image (ubi8/openjdk-11) and our application image (appuio-spring-boot-ex). The ImageStream is an abstraction for referencing images from within OpenShift Container Platform. Simplified the ImageStream tracks changes for the defined images and reacts by triggering a new Build.

**TODO: Check if everything is working**

```YAML
apiVersion: image.openshift.io/v1
kind: ImageStream
metadata:
  annotations:
    openshift.io/generated-by: OpenShiftNewBuild
  creationTimestamp: null
  labels:
    build: data-producer
    application: amm-techlab
  name: data-producer
spec:
  lookupPolicy:
    local: false
status:
  dockerImageRepository: ""
---
apiVersion: image.openshift.io/v1
kind: ImageStream
metadata:
  labels:
    app: appuio-spring-boot-ex
    application: amm-techlab
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
imagestream.image.openshift.io/data-producer created
imagestream.image.openshift.io/openjdk-11 created
```


## Task {{% param sectionnumber %}}.5: Deploy Application

After the ImageStream definition we can setup our Deployment. Please note the Deployment annotation `image.openshift.io/triggers`, this annotation connects the Deployment with the ImageStreamTag (which is automatically created by the ImageSource object)

```YAML
apiVersion: v1
kind: DeploymentConfig
metadata:
  annotations:
    image.openshift.io/triggers: '[{"from":{"kind":"ImageStreamTag","name":"data-producer:latest"},"fieldPath":"spec.template.spec.containers[?(@.name==\"data-producer\")].image"}]'
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
              port: 8080
              scheme: HTTP
            initialDelaySeconds: 3
            periodSeconds: 20
            successThreshhold: 1
            timeoutSeconds: 15
          readinessProbe:
            failureThreshold: 5
            httpGet:
              path: /health
              port: 8080
              scheme: HTTP
            initialDelaySeconds: 3
            periodSeconds: 20
            successThreshold: 1
            timeoutSeconds: 15
          name: data-producer
          port:
            - containerPort: 8080
              name: http
              protocol: TCP
          resources:
            limits:
              cpu: "1"
              memory: 500Mi
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
          name: data-producer:latest
      type: ImageChange
    - type: ConfigChange
  
```

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/content/en/docs/02.0/2.1/deployment.yaml)

Let's create the deployment with following command

```BASH
oc create -f https://raw.githubusercontent.com/puzzle/amm-techlab/master/content/en/docs/02.0/2.1/deployment.yaml
```

```
deployment/data-producer created
```

When you check your project in the web console (Developer view) the example app is visible.
The pod will be deployed successfully when the build finishes and the application image is pushed to the image stream. Please note this might take several minutes.


## Task {{% param sectionnumber %}}.6: Create Service

Expose the container ports to the to the cluster with a Service. For the Service we configure the port `8080` for the Web API. We set the Service type to ClusterIP to expose the Service cluster internal only.

```YAML
apiVersion: v1
kind: Service
metadata:
  name: quarkus-producer
  labels:
    application: quarkus-producer
spec:
  ports:
  - name: 8080-tcp
    port: 8080
    protocol: TCP
    targetPort: 8080
  selector:
    deployment: quarkus-producer
  sessionAffinity: None
  type: ClusterIP
```

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/content/en/docs/02.0/2.1/svc.yaml)

Create the Service in OpenShift

```bash
oc create -f https://raw.githubusercontent.com/puzzle/amm-techlab/master/content/en/docs/02.0/2.1/svc.yaml
```

```
service/data-producer created
```


## Task {{% param sectionnumber %}}.7: Create Route

Create a Route to expose the service at a host name. This will make the application available outside of the cluster.

The TLS type is set to Edge. That will configure the router to terminate the SSL connection and forward to the service with HTTP.

```YAML
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  labels:
     application: amm-techlab
  name: quarkus-producer
  port:
    targetPort: 8080-tcp
  to:
    kind: Service
    name: quarkus-producer
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
route.route.openshift.io/data-consumer created
```


## Task {{% param sectionnumber %}}.8: Verify deployed resources

Now we can list all resources in our project to double check if everything is up und running.
Use the following command to display all resources within our project.

```BASH
oc get all
```

```
{{< highlight text "hl_lines=9 22" >}}
TODO
{{< / highlight >}}
```


## Task {{% param sectionnumber %}}.9: Access application by browser

Finally you can visit your application with the URL provided from the Route: <https://appuio-spring-boot-ex-spring-boot-userXY.techlab.openshift.ch/>

> Replace `userXY with your username or get the url from your route.
