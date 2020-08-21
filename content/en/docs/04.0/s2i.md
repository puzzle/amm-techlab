---
title: "4.1 Source to Image"
linkTitle: "Source to Image"
weight: 410
sectionnumber: 4.1
description: >
  Building images using Source to Image.
---


## {{% param sectionnumber %}}.1 Lab


## TODO Lab

S2I: Die Teilnehmer werden an den Source 2 Image Workflow geführt in dem sie:

* [ ] Build Config als YAML erstellen, ihr Gitrepo (private Repo) angeben, dort liegt die Source
* [ ] oc apply der Build Config YAML auf ihrem Namespace ausführen und den Build anschauen
* [ ] Git Secret erstellen und in der build Config angeben und erneut oc apply und build erneut triggern -> build geht
* [ ] DeploymentConfig, Service, Route auch noch via oc apply erstellen und dann entsprechend die App aufrufen
* [ ] Additional teil: Repo Forken und in der BC anpassen, danach ein S2I script überschreiben und einen echo Befehl integrieren um zu zeigen wie das funktionieren kann.
* [ ] Proxy Setzen beschreiben
* [ ] Builder image von   `registry.access.redhat.com/redhat-openjdk-18/openjdk18-openshift` vorgängig importieren? (oc import-image )
* [ ] Welches repository als Source für Si2 verwenden? 


* init command `oc new-app --name s2i registry.redhat.io/redhat-openjdk-18/openjdk18-openshift~https://github.com/appuio/example-spring-boot-helloworld --as-deployment-config=true`


## TODO Vorbereitung

* [ ] privates Git Repo mit Sourcen und Deploy Key erstellen
  * Deploy Key zur Verfügung stellen


Source-to-Image (S2I) builds are a special way to inject application source code into a builder image and assembling a new runnable image. There are several builder image available, each for its own framework or language.

The main reasons to use this build strategy are.

* Speed - The assemble process where the source code is injected into the image is a single Docker layer. This reduce the build time and resources. Furthermore S2I allows incremental builds.
* Security - Dockerfiles are usually running as root and having access to the container network. This is a possible security risk. S2I Images allow more control what permissions and privileges are available to the builder image since the build launches only a single container. OpenShift allows cluster administrator tightly control what privileges developers have at build time.


## Create BuildConfig

First let's create a BuildConfig.

```YAML
apiVersion: build.openshift.io/v1
kind: BuildConfig
metadata:
  annotations:
    openshift.io/generated-by: OpenShiftNewApp
  labels:
    app: spring-boot-s2i
  name: spring-boot-s2i
spec:
  failedBuildsHistoryLimit: 5
  output:
    to:
      kind: ImageStreamTag
      name: spring-boot-s2i:latest
  runPolicy: Serial
  source:
    git:
      uri: https://github.com/schlapzz/spring-boot-private
    type: Git
  strategy:
    sourceStrategy:
      from:
        kind: ImageStreamTag
        name: openjdk18-openshift:latest
    type: Source
  successfulBuildsHistoryLimit: 5
  triggers:
  - github:
      secret: 5ixnYii7WPsF1WY1HE_J
    type: GitHub
  - generic:
      secret: yDGx9GtfIUkBQOyi2usf
    type: Generic
  - type: ConfigChange
  - imageChange:
      lastTriggeredImageID: registry.redhat.io/redhat-openjdk-18/openjdk18-openshift@sha256:648f77558d4656107be73379219d6d2ab27a092e92a956d96737b6b0fae5000a
    type: ImageChange
```

```YAML
apiVersion: image.openshift.io/v1
kind: ImageStream
metadata:
  labels:
    app: spring-boot-s2i
  name: spring-boot-s2i
  namespace: amm-cschlatter
spec:
  lookupPolicy:
    local: false
```


```YAML
apiVersion: image.openshift.io/v1
kind: ImageStream
metadata:
  labels:
    app: spring-boot-s2i
  name: openjdk18-openshift
spec:
  lookupPolicy:
    local: false
  tags:
  - annotations:
      openshift.io/imported-from: registry.redhat.io/redhat-openjdk-18/openjdk18-openshift
    from:
      kind: DockerImage
      name: registry.redhat.io/redhat-openjdk-18/openjdk18-openshift
    generation: 2
    importPolicy: {}
    name: latest
    referencePolicy:
      type: Source
```

Let's check if the build is complete.

```BASH
oc get builds
```


```
NAME                TYPE     FROM          STATUS                        STARTED          DURATION
spring-boot-s2i-1   Source   Git           Failed (FetchSourceFailed)    42 minutes ago
```

Now you can see the build failed. Let's figure out why.

## Troubleshooting


```BASH
oc describe build spring-boot-s2i-1
```

```

We can see the following output (example is truncated)
......

Log Tail:  Cloning "https://github.com/schlapzz/spring-boot-private" ...
    error: failed to fetch requested repository "https://github.com/schlapzz/spring-boot-private" with provided credentials
Events:
  Type    Reason    Age      From                Message
  ----    ------    ----      ----                -------
  Normal  Scheduled  2m19s      default-scheduler            Successfully assigned amm-cschlatter/spring-boot-s2i-2-build to ip-10-130-137-159.eu-central-1.compute.internal
  Normal  Started    2m17s      kubelet, ip-10-130-137-159.eu-central-1.compute.internal  Started container git-clone
  Normal  AddedInterface  2m17s      multus                Add eth0 [10.124.2.30/23]
  Normal  Pulled    2m17s      kubelet, ip-10-130-137-159.eu-central-1.compute.internal  Container image "quay.io/openshift-release-dev/
....
```

Under the section Log Tail we can see that fetching our private repository failed. This is beacuse we try to fetch the source from a private repository without providing the credentials.


## Fix config

In this step we're going to create a secret for our Git credentials. There are a few different authentication methods [8.3.4.2. Source Clone Secrets](https://access.redhat.com/documentation/en-us/openshift_container_platform/3.11/html/developer_guide/builds#source-code). For this example we use the Basic Authentication. But instead of a user and password combination we use a username and token credentials.

//TODO: Add how to generate access tokens / or how to get deploy key


```BASH
echo 'password' | base64
echo 'token' | base64
```


```YAML
apiVersion: v1
data:
  password: <Base64 decoded password>
  username: <Base64 decoded token>
kind: Secret
metadata:
  name: git-credentials
type: kubernetes.io/basic-auth
```

Then we can create the secret

```BASH
oc create -f git-credentials.yaml
```

Next we reference the freshly create secret in out BuildConfig

```YAML
apiVersion: build.openshift.io/v1
kind: BuildConfig
metadata:
  annotations:
    openshift.io/generated-by: OpenShiftNewApp
  labels:
    app: spring-boot-s2i
  name: spring-boot-s2i
spec:
  failedBuildsHistoryLimit: 5
  output:
    to:
      kind: ImageStreamTag
      name: spring-boot-s2i:latest
  runPolicy: Serial
  source:
    git:
      uri: https://github.com/schlapzz/spring-boot-private
    type: Git
    sourceSecret:
      name: git-credentials
  strategy:
    sourceStrategy:
      from:
        kind: ImageStreamTag
        name: openjdk18-openshift:latest
    type: Source
  successfulBuildsHistoryLimit: 5
  triggers:
  - github:
      secret: 5ixnYii7WPsF1WY1HE_J
    type: GitHub
  - generic:
      secret: yDGx9GtfIUkBQOyi2usf
    type: Generic
  - type: ConfigChange
  - imageChange:
      lastTriggeredImageID: registry.redhat.io/redhat-openjdk-18/openjdk18-openshift@sha256:648f77558d4656107be73379219d6d2ab27a092e92a956d96737b6b0fae5000a
    type: ImageChange
```

Now we can trigger the build again.

```BASH
oc start-build spring-boot-s2i
```

You can watch the Build status with following command. You can quit the watch function anytime with `ctrl + c`

```BASH
oc get builds spring-boot-s2i-2 -w
```



## Create additional resources

Until now we just created the build resources. Up next is the creation of the DeploymentConfig, Serve and the Route.

### DeplyomentConfig


### Service

```YAML
apiVersion: v1
kind: Service
metadata:
  labels:
    app: spring-boot-s2i
  name: spring-boot-s2i
spec:
  ports:
  - name: 8080-tcp
    port: 8080
    protocol: TCP
    targetPort: 8080
  - name: 8443-tcp
    port: 8443
    protocol: TCP
    targetPort: 8443
  - name: 8778-tcp
    port: 8778
    protocol: TCP
    targetPort: 8778
  selector:
    deployment: spring-boot-s2i
  sessionAffinity: None
  type: ClusterIP
```


### Route


```YAML
```

Do you not find a suitable S2I builder image for you application. [Create your own](https://www.openshift.com/blog/create-s2i-builder-image).
[S2I Build Strategy](https://docs.openshift.com/container-platform/4.5/builds/build-strategies.html#build-strategy-s2i_build-strategies)