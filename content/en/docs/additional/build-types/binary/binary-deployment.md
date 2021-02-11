---
title: "9.2.2 Binary Deployment"
linkTitle: "Binary Deployment"
weight: 922
sectionnumber: 9.2.2
description: >
  Building images from binary using Binary Build.
---


## {{% param sectionnumber %}}.1 Lab


<!-- ## TODO Lab

* [ ] DeploymentConfig, Service, Route auch noch via oc apply erstellen und dann entsprechend die App aufrufen
* [ ] Hinweis eigenes Build Image verwenden, falls in ext. privater Registry -> Proxy Einstellungen
 -->

{{% alert  color="primary" %}}Binary builds require content from the local file system. Therefore automatic triggering a build is not possible.{{% /alert %}}


### Uses cases of binary builds

* Build and test code local
* Bypass the SCM
* Build images with artifacts from different sources


### BuildConfig

Let's create the resources for our binary deployment. We start with the ImageStreams. There are two definitions, the first one represents our builder image. The second ImageStream is used for our build binary deployment.

{{< highlight yaml >}}{{< readfile file="content/en/docs/additional/build-types/binary/imageStreams.yaml" >}}{{< /highlight >}}

[Source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/content/en/docs/additional/build-types/binary/imageStreams.yaml)

```BASH
oc create -f https://raw.githubusercontent.com/puzzle/amm-techlab/master/content/en/docs/additional/build-types/binary/imageStreams.yaml
```

Afterwards we can create the Build Config for the binary deployment.

{{< highlight yaml >}}{{< readfile file="content/en/docs/additional/build-types/binary/buildConfig.yaml" >}}{{< /highlight >}}

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
