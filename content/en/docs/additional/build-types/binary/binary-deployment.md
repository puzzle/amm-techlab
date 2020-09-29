---
title: "Binary Deployment"
linkTitle: "9.2.2 Binary Deployment"
weight: 922
sectionnumber: 9.2.2
description: >
  Building images from binary using Binary Build.
---


## {{% param sectionnumber %}}.1 Lab


## TODO Lab

* [ ] Build Config erstellen, Binary Deployment
* [ ] oc new-build mit from file, das artefakt ist ein Jar file, das von github herunter geladen werden kann, direkt integriert in den Lab Dokumenten.
* [ ] DeploymentConfig, Service, Route auch noch via oc apply erstellen und dann entsprechend die App aufrufen
* [ ] Hinweis eigenes Build Image verwenden, falls in ext. privater Registry -> Proxy Einstellungen


> Binary builds require content from the local file system. Therefore automatic triggering a build is not possible.


### Uses cases of binary builds

* Build and test code local
* Bypass the SCM
* Build images with artifacts from different sources


### BuildConfig

Let's create the resources for our binary deployment. We start with the ImageStreams. There are two definitions, the first one represents our builder image. The second ImageStream is used for our build binary deployment.


```YAML

apiVersion: image.openshift.io/v1
kind: ImageStream
metadata:
  annotations:
    openshift.io/generated-by: OpenShiftNewBuild
  labels:
    build: spring-boot-bb
  name: wildfly-160-centos7
spec:
  lookupPolicy:
    local: false
  tags:
  - annotations:
      openshift.io/imported-from: openshift/wildfly-160-centos7
    from:
      kind: DockerImage
      name: openshift/wildfly-160-centos7
    importPolicy: {}
    name: latest
    referencePolicy:
      type: ""
---  
apiVersion: image.openshift.io/v1
kind: ImageStream
metadata:
  annotations:
    openshift.io/generated-by: OpenShiftNewBuild
  labels:
    build: spring-boot-bb
  name: spring-boot-bb
spec:
  lookupPolicy:
    local: false
```

[Source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/content/en/docs/additional/build-types/binary/imageStreams.yaml)

```BASH
oc create -f https://raw.githubusercontent.com/puzzle/amm-techlab/master/content/en/docs/additional/build-types/binary/imageStreams.yaml
```

Afterwards we can create the Build Config for the binary deployment.

```YAML
apiVersion: build.openshift.io/v1
kind: BuildConfig
metadata:
  annotations:
    openshift.io/generated-by: OpenShiftNewBuild
  labels:
    build: spring-boot-bb
  name: spring-boot-bb
spec:
  output:
    to:
      kind: ImageStreamTag
      name: spring-boot-bb:latest
  postCommit: {}
  resources: {}
  source:
    binary: {}
    type: Binary
  strategy:
    sourceStrategy:
      from:
        kind: ImageStreamTag
        name: wildfly-160-centos7:latest
    type: Source
  triggers:
  - github:
      secret: u7kQquuC1Hpap8pv82Xz
    type: GitHub
  - generic:
      secret: MduzcwKRw37WrDWWSfCf
    type: Generic
status:
  lastVersion: 0
```


[Source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/content/en/docs/additional/build-types/binary/buildConfig.yaml)

```BASH
oc create -f https://raw.githubusercontent.com/puzzle/amm-techlab/master/content/en/docs/additional/build-types/binary/buildConfig.yaml
```

The next step is to prepare our binary. We're going to use a prebuilt WAR file from appuio.

```BASH
mkdir tmp-bin
cd tmp-bin
mkdir deployments
wget -O deployments/ROOT.war 'https://github.com/appuio/hello-world-war/blob/master/repo/ch/appuio/hello-world-war/1.0.0/hello-world-war-1.0.0.war?raw=true'
```

Now we can start our build with following command:

```BASH
oc start-build spring-boot-bb --from-dir=. --follow
```
