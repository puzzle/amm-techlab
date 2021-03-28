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
* [x] DeploymentConfig, Service, Route auch noch via oc apply erstellen und dann entsprechend die App aufrufen
* [ ] Hinweis eigenes Build Image verwenden, falls in ext. privater Registry -> Proxy Einstellungen
 -->

{{% alert  color="primary" %}}Binary builds require content from the local file system. Therefore automatic triggering a build is not possible.{{% /alert %}}


### Uses cases of binary builds

* Build and test code local
* Bypass the SCM
* Build images with artifacts from different sources


We first check that the project is ready for the lab.

Ensure that the `LAB_USER` environment variable is set.

```bash
echo $LAB_USER
```

If the result is empty, set the `LAB_USER` environment variable.

<details><summary>command hint</summary>

```bash
export LAB_USER=<username>
```

</details><br/>


Change to your main Project.

<details><summary>command hint</summary>

```bash
oc project $LAB_USER-build-types
```

</details><br/>


## Task {{% param sectionnumber %}}.2: Binary Build


### BuildConfig

Let's create the resources for our binary deployment. We start with the ImageStreams. There are two definitions, the first one represents our builder image. The second ImageStream is used for our build binary deployment.

{{< highlight yaml >}}{{< readfile file="manifests/additional/binary/imageStreams.yaml" >}}{{< /highlight >}}

[Source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/additional/binary/imageStreams.yaml)

```BASH
oc create -f https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/additional/binary/imageStreams.yaml
```

Afterwards we can create the Build Config for the binary deployment.

{{< highlight yaml >}}{{< readfile file="manifests/additional/binary/buildConfig.yaml" >}}{{< /highlight >}}

[Source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/additional/binary/buildConfig.yaml)

```BASH
oc create -f https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/additional/binary/buildConfig.yaml
```


The next step is to prepare our binary. We're going to use a prebiuld quarkus binary from the data producer REST version.

```BASH
mkdir bin
cd bin
wget 'https://github.com/puzzle/quarkus-techlab-data-producer/releases/download/1.1.0-rest/application'
```


Next we need to configre a Dockerfile. This is necessary because there exists no prebuilt s2i image for binary applications.
{{< highlight dockerfile >}}{{< readfile file="manifests/additional/binary/Dockerfile" >}}{{< /highlight >}}

[Source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/additional/binary/Dockerfile)


Now we can start our build with following command:

```BASH
oc start-build quarkus-techlab-data-producer-bb --from-dir=. --follow
```

This command triggers a build from the current directory which contains the binary and the Dockerfile.


## Create additional resources

Until now we just created the build resources. Up next is the creation of the DeploymentConfig, Service and the Route.


### DeploymentConfig

{{< highlight yaml >}}{{< readfile file="manifests/additional/binary/deploymentConfig.yaml" >}}{{< /highlight >}}

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/additional/binary/deploymentConfig.yaml)

```BASH
oc process -f https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/additional/binary/deploymentConfig.yaml -p PROJECT_NAME=$PROJECT_NAME | oc apply -f -
```


### Service

{{< highlight yaml >}}{{< readfile file="manifests/additional/binary/service.yaml" >}}{{< /highlight >}}

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/additional/binary/service.yaml)

```BASH
oc create -f https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/additional/binary/service.yaml
```


### Route

{{< highlight yaml >}}{{< readfile file="manifests/additional/binary/route.yaml" >}}{{< /highlight >}}

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/additional/binary/route.yaml)

Then we can create the route

```bash
oc process -f https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/additional/binary/route.yaml -p HOSTNAME=quarkus-techlab-data-producer-bb-$USER_NAME.{{% param techlabClusterDomainName %}} | oc apply -f -
```

Check if the route was created successfully

```BASH
oc get route quarkus-techlab-data-producer-binary
```


```
NAME              HOST/PORT                                          PATH   SERVICES          PORT       TERMINATION   WILDCARD
quarkus-techlab-data-producer-binary   quarkus-techlab-data-producer-bb-<username>.{{% param techlabClusterDomainName %}}          quarkus-techlab-data-producer-binary   8080-tcp   edge          None
```

And finally check if you can reach your application within a browser by accessing the public route. `https://quarkus-techlab-data-producer-bb-<username>.{{% param techlabClusterDomainName %}}`

