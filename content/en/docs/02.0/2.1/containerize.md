---
title: "2.1 Containerize an application"
linkTitle: "2.1 Containerize an application"
weight: 21
sectionnumber: 2.1
description: >
  Containerize an application.
---

The main goal of this lab is to show you how to containerize a Java application. Including deployment on OpenShift and exposing the service with a route. In this example, we want to build a microservice-based on [Quarkus](https://quarkus.io/), which produces random data when it’s REST interface is called. Another Quarkus microservice consumes then the data and exposes it to its endpoint.

```
+----------+                    +----------+
| producer +<-------------------+ consumer +
+----------+                    +----------+
```

Some words about Quarkus:

{{% alert  color="primary" %}}
“Quarkus is a Kubernetes Native Java stack tailored for GraalVM & OpenJDK HotSpot, crafted from the best of breed Java libraries and standards. Also focused on developer experience, making things just work with little to no configuration and allowing to do live coding.” - [quarkus.io](https://quarkus.io/)
{{% /alert %}}

In short, Quarkus brings a framework built upon JakartaEE standards to build microservices in the Java environment. Per default, Quarkus comes with full CDI integration, RESTeasy-JAX-RS, dev mode and many more features.

If you wanna know more about Quarkus, you can checkout our [Puzzle Quarkus Techlab](https://puzzle.github.io/quarkus-techlab/)

The source code of our Quarkus applications is available on Github:

* [Consumer](https://github.com/puzzle/quarkus-techlab-data-consumer)
* [Producer](https://github.com/puzzle/quarkus-techlab-data-producer)


## Task {{% param sectionnumber %}}.1: Inspect Dockerfile

First, we need a Dockerfile that defines the application transformation from source code to a container image.

To build the producer, we make use of the Docker Multistage build feature. In the first stage, we use the [centOS Quarkus image](https://quay.io/repository/quarkus/centos-quarkus-maven?tag=20.1.0-java11) and perform a Quarkus native build. The resulting binary will be used in the second build stage. For the second stage, we use the UBI minimal image.
(see [best practices](../../additional/container-best-practices/bestpractice/#use-multistage-build) for more information on Multistage builds)

```Dockerfile
## Stage 1 : build with maven builder image with native capabilities
FROM quay.io/quarkus/centos-quarkus-maven:20.1.0-java11 AS build
COPY pom.xml /usr/src/app/
RUN mvn -f /usr/src/app/pom.xml -B de.qaware.maven:go-offline-maven-plugin:1.2.5:resolve-dependencies
COPY src /usr/src/app/src
USER root
RUN chown -R quarkus /usr/src/app
USER quarkus
RUN mvn -f /usr/src/app/pom.xml -Pnative clean package

## Stage 2 : create the docker final image
FROM registry.access.redhat.com/ubi8/ubi-minimal
WORKDIR /work/
COPY --from=build /usr/src/app/target/*-runner /work/application

# set up permissions for user `1001`
RUN chmod 775 /work /work/application \
  && chown -R 1001 /work \
  && chmod -R "g+rwX" /work \
  && chown -R 1001:root /work

EXPOSE 8080
USER 1001

CMD ["./application", "-Dquarkus.http.host=0.0.0.0"]
```

[source](https://raw.githubusercontent.com/puzzle/quarkus-techlab-data-producer/master/src/main/docker/Dockerfile.multistage)

Because the build needs a huge amount of memory (>8GB) and takes a lot of time (+5min) we refrain from building the app from source. Instead, we take the pre-built Quarkus app from the Github release page.

```Dockerfile
FROM registry.access.redhat.com/ubi8/ubi
WORKDIR /work/

# Install wget
RUN yum install wget -y

# Fetch the latest binary release from the GutHub release page
RUN wget https://github.com/puzzle/quarkus-techlab-data-producer/releases/download/1.0.0-rest/application

RUN chmod -R 775 /work
EXPOSE 8080

# Run the application
CMD ["./application", "-Dquarkus.http.host=0.0.0.0"]
```

[source](https://raw.githubusercontent.com/puzzle/quarkus-techlab-data-producer/rest/src/main/docker/Dockerfile.binary)

This Dockerfile will be used to build the image inside OpenShift.


## Task {{% param sectionnumber %}}.2: Create ImageStream

We configure an [ImageStream](https://docs.openshift.com/container-platform/4.5/openshift_images/image-streams-manage.html) for the image that we will build inside OpenShift. ImageStream is an abstraction for referencing images from within OpenShift Container Platform. Simplified the ImageStream tracks changes for the defined images and reacts by triggering a new Build. This image reference will also be used to deploy the application.

Prepare a file inside your workspace `<workspace>/imageStream.yaml` and add the following resource configuration:

```YAML
apiVersion: image.openshift.io/v1
kind: ImageStream
metadata:
  labels:
    build: data-producer
    application: amm-techlab
  name: data-producer
```

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/02.0/2.1/imageStream.yaml)

Let's create the ImageStream

```BASH
oc apply -f imageStream.yaml
```

Expected output:

```
imagestream.image.openshift.io/data-producer created
```


## Task {{% param sectionnumber %}}.3: Create BuildConfig

In this section, we create a OpenShift build that uses our Dockerfile to build the image for the producer.

The [BuildConfig](https://docs.openshift.com/container-platform/4.5/builds/understanding-buildconfigs.html) describes how a single build task is performed. The BuildConfig is primarily characterized by the Build strategy and its resources. For our build, we use the Docker strategy which invokes the Docker build command. Furthermore, it expects a `Dockerfile` in the source repository. If the Dockerfile is not in the root directory, then you can specify the location with the `dockerfilePath`.
Beside we configure the source and the triggers as well. For the source, we can specify any Git repository. This is where the application sources reside. The triggers describe how to trigger the build. In this example, we provide four different triggers. (Generic webhook, GitHub webhook, ConfigMap change, Image change)

Prepare a file inside your workspace `<workspace>/buildConfig.yaml` and add the following resource configuration:

```YAML
apiVersion: build.openshift.io/v1
kind: BuildConfig
metadata:
  labels:
    build: data-producer
    application: amm-techlab
  name: data-producer
spec:
  output:
    to:
      kind: ImageStreamTag
      name: data-producer:rest
  resources:
    limits:
      cpu: "500m"
      memory: "512Mi"
    requests:
      cpu: "250m"
      memory: "512Mi"
  source:
    git:
      uri: https://github.com/puzzle/quarkus-techlab-data-producer.git
      ref: rest
    type: Git
  strategy:
    dockerStrategy:
      dockerfilePath: src/main/docker/Dockerfile.binary
    type: Docker
  triggers:
  - generic:
      secret: f31PWzHXBGI9iYw-fTli
    type: Generic
  - type: ConfigChange
  - imageChange: {}
    type: ImageChange
```

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/02.0/2.1/buildConfig.yaml)

Create the build config by applying the content of your `buildConfig.yaml` file.

<details><summary>command hint</summary>

```BASH
oc apply -f buildConfig.yaml
```

</details><br/>

Expected output:

```
buildconfig.build.openshift.io/data-producer created
```

The build starts automatically after creating the buildConfig. See the actual build logs:

```BASH
oc logs -f data-producer-1-build
```

{{% alert title="Note" color="primary" %}} The `-f` option streams the log output during the whole build. Exit stream before the build is done by pressing `Ctrl+C`. {{% /alert %}}


## Task {{% param sectionnumber %}}.4: Deploy Application

After the ImageStream and BuildConfig definition, we can set up our DeploymentConfig. The DeploymentConfig defines how our image is run inside OpenShift. The image is referenced by our ImageStream `data-producer` with the `rest` tag.

Prepare a file inside your workspace `<workspace>/producer.yaml` and add the following resource configuration:

```YAML
apiVersion: v1
kind: DeploymentConfig
metadata:
  annotations:
    image.openshift.io/triggers: '[{"from":{"kind":"ImageStreamTag","name":"data-producer:rest"},"fieldPath":"spec.template.spec.containers[?(@.name==\"data-producer\")].image"}]'
  labels:
    app: data-producer
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
            successThreshold: 1
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
          ports:
            - containerPort: 8080
              name: http
              protocol: TCP
          resources:
            limits:
              cpu: '1'
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
          name: data-producer:rest
      type: ImageChange
    - type: ConfigChange
```

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/02.0/2.1/producer.yaml)

Let's create the deployment

<details><summary>command hint</summary>

```BASH
oc apply -f producer.yaml
```

</details><br/>

Expected output:

```
deploymentconfig.apps.openshift.io/data-producer created
```

When you check your project in the web console (Developer view) the example app is visible.
The pod will be deployed successfully when the build finishes and the application image is pushed to the image stream. Please note this might take several minutes.


## Task {{% param sectionnumber %}}.5: Create Service

Services are used as bridges between the container and the OpenShift project. They enable access from an OpenShift project to the port of a container.

Expose the container ports to the cluster with a Service. For the Service, we configure the port `8080` for the Web API. We set the Service type to ClusterIP to expose the Service cluster internal only.

Prepare a file inside your workspace `<workspace>/svc.yaml` and add the following resource configuration:

```YAML
apiVersion: v1
kind: Service
metadata:
  name: data-producer
  labels:
    application: amm-techlab
spec:
  ports:
  - name: http
    port: 8080
    protocol: TCP
    targetPort: http
  selector:
    deploymentConfig: data-producer
  sessionAffinity: None
  type: ClusterIP
```

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/02.0/2.1/svc.yaml)

Create the Service in OpenShift

<details><summary>command hint</summary>

```BASH
oc apply -f svc.yaml
```

</details><br/>

Expected output:

```
service/data-producer created
```


## Task {{% param sectionnumber %}}.6: Create Route

Create a Route to expose the service at a hostname. This will make the application available outside of the cluster.

The TLS type is set to Edge. That will configure the router to terminate the SSL connection and forward it to the service with HTTP.

Prepare a file inside your workspace `<workspace>/route.yaml` and add the following resource configuration:

```YAML
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  labels:
     application: amm-techlab
  name: data-producer
spec:
  port:
    targetPort: http
  to:
    kind: Service
    name: data-producer
    weight: 100
  tls:
    termination: edge
  wildcardPolicy: None
```

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/02.0/2.1/route.yaml)


Create the Route in OpenShift

<details><summary>command hint</summary>

```BASH
oc apply -f route.yaml
```

</details><br/>

Expected output:

```
route.route.openshift.io/data-producer created
```


## Task {{% param sectionnumber %}}.7: Verify deployed resources

Now we can list all resources in our project to double-check if everything is up and running.
Use the following command to display all resources within our project.

```BASH
oc get all
```

```
{{< highlight text "hl_lines=" >}}
NAME                         READY   STATUS      RESTARTS   AGE
pod/data-producer-1-build    0/1     Completed   0          4m4s
pod/data-producer-1-deploy   0/1     Completed   0          2m44s
pod/data-producer-1-h4bwj    1/1     Running     0          2m41s

NAME                                    DESIRED   CURRENT   READY   AGE
replicationcontroller/data-producer-1   1         1         1       2m44s

NAME                    TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/data-producer   ClusterIP   172.30.211.87   <none>        8080/TCP   3m54s

NAME                                               REVISION   DESIRED   CURRENT   TRIGGERED BY
deploymentconfig.apps.openshift.io/data-producer   1          1         1         config,image(data-producer:rest)

NAME                                           TYPE     FROM       LATEST
buildconfig.build.openshift.io/data-producer   Docker   Git@rest   1

NAME                                       TYPE     FROM          STATUS     STARTED         DURATION
build.build.openshift.io/data-producer-1   Docker   Git@838be5c   Complete   4 minutes ago   1m21s

NAME                                           IMAGE REPOSITORY                                                                              TAGS   UPDATED
imagestream.image.openshift.io/data-producer   image-registry.openshift-image-registry.svc:5000/hanelore15/data-producer   rest   2 minutes ago

NAME                                     HOST/PORT                                                         PATH   SERVICES        PORT       TERMINATION   WILDCARD
route.route.openshift.io/data-producer   data-producer-hanelore15.techlab.openshift.ch          data-producer   8080-tcp   edge          None

{{< / highlight >}}
```


## Task {{% param sectionnumber %}}.9: Access application by browser

Finally, you can visit your application with the URL provided from the Route: <https://data-producer-userXY.techlab.openshift.ch/data>

{{% alert  color="primary" %}}Replace **userXY** with your username or get the URL from your route.{{% /alert %}}

When you open the URL you should see the producers data

```json
{"data":0.6681209742895893}
```

If you only see `Your new Cloud-Native application is ready!`, then you forget to append the `/data`path to the URL.


## Task {{% param sectionnumber %}}.10: Deploy consumer application

Now it's time to deploy the counterpart. The consumer application consists of three resource definitions:

the deployment
: pointing to the consumer Container Image on docker Hub

the service
: which exposes the application inside our cluster

the route
: to access the application from outside the cluster

Consumer and producer are of different kind of deployment resources. The producer is a DeploymentConfig (OpenShift) and the consumer a Deployment (Kubernetes). The producer needs to be a DeploymentConfig to make full use of the build process with ImageStreams. Because the consumer uses an external image and doesn't need these features we can follow the best practices and use the Kubernetes-native Deployment.

We get the needed [consumer.yaml](https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/02.0/2.1/consumer.yaml) by curl. Execute the following command inside your workspace:

```BASH
curl https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/02.0/2.1/consumer.yaml --output consumer.yaml
```

This should have created the file `<workspace>/consumer.yaml` containing all resource definitions. Open it with your IDE to see the resource definitions.

Use the file `consumer.yaml` to create the consumer application inside OpenShift.

<details><summary>command hint</summary>

```BASH
oc apply -f consumer.yaml
```

</details><br/>

Expected output:

```
deployment.apps/data-consumer created
service/data-consumer created
route.route.openshift.io/data-consumer created
```

Let's verify if everything was deployed and is up running. Show again all resources.

<details><summary>command hint</summary>

```BASH
oc get all
```

</details><br/>

Expected resources in the output:

```
NAME                                 READY   STATUS             RESTARTS   AGE
pod/data-consumer-7f44cc5647-q2hqc   1/1     Running            0          4m38s
pod/data-producer-1-build            0/1     Completed          0          10m
pod/data-producer-1-deploy           0/1     Completed          0          9m33s
pod/data-producer-1-h4bwj            1/1     Running            0          9m30s

NAME                                    DESIRED   CURRENT   READY   AGE
replicationcontroller/data-producer-1   1         1         1       9m33s

NAME                    TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/data-consumer   ClusterIP   172.30.22.100   <none>        8080/TCP   4m38s
service/data-producer   ClusterIP   172.30.211.87   <none>        8080/TCP   10m

NAME                            READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/data-consumer   1/1     1            1           4m38s

NAME                                       DESIRED   CURRENT   READY   AGE
replicaset.apps/data-consumer-7f44cc5647   1         1         0       4m38s

NAME                                               REVISION   DESIRED   CURRENT   TRIGGERED BY
deploymentconfig.apps.openshift.io/data-producer   1          1         1         config,image(data-producer:rest)

NAME                                           TYPE     FROM       LATEST
buildconfig.build.openshift.io/data-producer   Docker   Git@rest   1

NAME                                       TYPE     FROM          STATUS     STARTED          DURATION
build.build.openshift.io/data-producer-1   Docker   Git@838be5c   Complete   10 minutes ago   1m21s

NAME                                           IMAGE REPOSITORY                                                                              TAGS   UPDATED
imagestream.image.openshift.io/data-producer   image-registry.openshift-image-registry.svc:5000/hanelore15/data-producer   rest   9 minutes ago

NAME                                     HOST/PORT                                                         PATH   SERVICES        PORT       TERMINATION   WILDCARD
route.route.openshift.io/data-consumer   data-consumer-hanelore15.techlab.openshift.ch   /      data-consumer   <all>      edge/Allow    None
route.route.openshift.io/data-producer   data-producer-hanelore15.techlab.openshift.ch          data-producer   8080-tcp   edge          None
```

Now you can visit the consumer the URL provided from the Route: <https://data-consumer-userXY.techlab.openshift.ch/data>

{{% alert  color="primary" %}}Replace **userXY** with your username or get the URL from your route.{{% /alert %}}

When you open the URL you should see the consumers data that he received from the producer

```json
{"data":0.6681209742895893}
```


## Solution

The needed resource files are available inside the folder [manifests/02.0/2.1/](https://github.com/puzzle/amm-techlab/tree/master/manifests/02.0/2.1) of the techlab [github repository](https://github.com/puzzle/amm-techlab).

When you were not successful, you can update your project with the solution by cloning the Techlab Repository `git clone https://github.com/puzzle/amm-techlab.git` and executing this command:

```BASH
oc apply -f manifests/02.0/2.1/
```
