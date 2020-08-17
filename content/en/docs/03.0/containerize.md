---
title: "3.1 Containerize an existing application"
linkTitle: "Containerize an existing application"
weight: 31
sectionnumber: 3.1
description: >
  Containerize an existing application.
---


## Containerize an existing application

### Setup Project

Prepare a new OpenShift project
```bash
oc new-project amm-spring-boot
``` 

Use an new folder for the Java project
```bash
mkdir amm-spring-boot
mkdir amm-spring-boot/config
mkdir amm-spring-boot/code
cd amm-spring-boot/config
``` 

Fork the sample project from appuio 
 https://github.com/appuio/example-spring-boot-helloworld .
 

### Dockerfile

First we need a Dockerfile. You can find the Dockerfile in the root directory of the example application

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


### BuildConfig


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
      uri: https://github.com/schlapzz/example-spring-boot-helloworld
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
### ImageStreams

Next we need to configure an [ImageStream](https://docs.openshift.com/container-platform/4.5/openshift_images/image-streams-manage.html) for the Java base image and our application.

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
    generation: 2
    importPolicy: {}
    name: latest
    referencePolicy:
      type: Source
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

### Route

Create a Route to expose the service at a host name

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



### Deploy resources

```bash
oc create -f .
```

```
buildconfig.build.openshift.io/appuio-spring-boot-ex created
deployment.apps/appuio-spring-boot-ex created
imagestream.image.openshift.io/appuio-spring-boot-ex created
imagestream.image.openshift.io/java-centos-openjdk11-jdk created
route.route.openshift.io/appuio-spring-boot-ex created
service/appuio-spring-boot-ex created
```


### Update source code
 Go to your forked GitHub Project and clone it.
 ```BASH
 cd ../source
 git clone https://github.com/<USERNAME>/example-spring-boot-helloworld .
 ```

After that you can open and modify the index.html. Finally commit and push your changes back to your forked repository.
```BASH
git add .
git commit -m "updated version"
git push origin/master
``` 

### Trigger build
- [ ] Manually or configure GitHub webhook?

#### Manually
Open the OpenShift Web GUI, choose Builds from the left Menu. Next to the listed Builds, press ┇ and Select "Start Build".
#### Webhook
- [ ] TODO?



### Configure application

In this stage we show you how to configure your application. There are several options how to configure an application, we will show how to do it with environment variables. You can overwrite every property in you `application.properties` file with the corresponding environment variable. (eg. server.port=8081 in the application.properties is the same like SERVER_PORT=8081 as an environment variable)

First open your `deployment.yaml` 

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
