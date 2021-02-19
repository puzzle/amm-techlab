---
title: "9.2.1 Source to Image"
linkTitle: "Source to Image"
weight: 921
sectionnumber: 9.2.1
description: >
  Building images using Source to Image.
---


## {{% param sectionnumber %}}.1 Lab

<!--
## TODO Lab

* [ ] Proxy Setzen beschreiben

-->

Source-to-Image (S2I) builds are a special way to inject application source code into a builder image and assembling a new runnable image. There are several builder image available, each for its own framework or language.

The main reasons to use this build strategy are.

* **Speed** - The assemble process where the source code is injected into the image is a single Docker layer. This reduce the build time and resources. Furthermore S2I allows incremental builds.
* **Security** - Dockerfiles are usually running as root and having access to the container network. This is a possible security risk. S2I Images allow more control what permissions and privileges are available to the builder image since the build launches only a single container. OpenShift allows cluster administrator tightly control what privileges developers have at build time.


## Setup

Create a new project, replace \<username> with your username.

```BASH
oc new-project amm-<username>
```


First we define the username and project name as environment variables. We're going to use them later for the Template parameters.

```BASH
export USER_NAME=<username>
export PROJECT_NAME=$(oc project -q)
```

>**Note:** If you already have a project called "quarkus-techlab-data-producer" under your Gitea user, you don't need to re-create it. Proceed with adding the  `.s2i/bin/assemble` file.

Next we clone the sample repository into our private git repo. Navigate to your Gitea instance `https://{{% param techlabGiteaUrl %}}/<username>` and click on create in the top right menu and select "New Migration". Use following parameters to clone the sample repository as a private repository:

* **Migrate / Clone From URL:** [https://github.com/puzzle/quarkus-techlab-data-producer.git](https://github.com/puzzle/quarkus-techlab-data-producer.git)
* **Owner:** \<username>
* **Repository Name:** quarkus-techlab-data-producer
* **Visibility:**  [x] Make Repository Private

Click "Migrate Repository"

After the migration is finished, create a new file `.s2i/bin/assemble` with following content in it

```BASH
#!/bin/bash
echo "assembling"

cd /tmp/src && ./mvnw package

ls -lah

echo "assembled"

exit
```


## Create BuildConfig

First let's create a BuildConfig. The important part in this specification are the source, output and strategy section.

* The source is pointing towards a private Git repository where the source code resides. Replace the git uri in the yaml below to your corresponding private git repo.
* We already discussed the strategy section in the beginning of this chapter. For this example we set the strategy to sourceStrategy (know as Source-to-Image / S2I)
* The last part is the output section. In our example we reference a ImageStreamTag as an output. This means the resulting image will be pushed into the internal registry and will be consumable as ImageStream.

{{< highlight yaml >}}{{< readfile file="manifests/additional/s2i/buildConfig.yaml" >}}{{< /highlight >}}

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/additional/s2i/buildConfig.yaml)

```BASH
oc process -f https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/additional/s2i/buildConfig.yaml -p GITREPOSITORY=https://{{% param techlabGiteaUrl %}}/$USER_NAME/quarkus-techlab-data-producer | oc apply -f -
```

Next we need the definitions for our two ImageStreamTag references.

The first resource configuration contains the definitions for the output image.

{{< highlight yaml "hl_lines=1-9" >}}{{< readfile file="manifests/additional/s2i/imageStreams.yaml" >}}{{< /highlight >}}

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/additional/s2i/imageStreams.yaml)

The second resource configuration references a S2I builder image. As builder Image we take the `ubi8/openjdk-11` image. This is already prepared for S2I builds.

{{< highlight yaml "hl_lines=11-30" >}}{{< readfile file="manifests/additional/s2i/imageStreams.yaml" >}}{{< /highlight >}}

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/additional/s2i/imageStreams.yaml)

```BASH
oc apply -f https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/additional/s2i/imageStreams.yaml
```

Let's check if the build is complete.

```BASH
oc get builds
```

```
NAME                TYPE     FROM          STATUS                        STARTED          DURATION
quarkus-techlab-data-producer-1   Source   Git           Failed (FetchSourceFailed)    2 minutes ago
```

Now you can see the build failed. Let's figure out why.


## Troubleshooting

First we describe our failed build with following command.

```BASH
oc describe build quarkus-techlab-data-producer-1
```

```
We can see the following output (example is truncated)
......

Log Tail:  Cloning "https://github.com/<username>/quarkus-techlab-data-producer" ...
    error: failed to fetch requested repository "https://github.com/<username>/quarkus-techlab-data-producer" with provided credentials
Events:
  Type    Reason    Age      From                Message
  ----    ------    ----      ----                -------
  Normal  Scheduled  2m19s      default-scheduler            Successfully assigned amm-cschlatter/quarkus-techlab-data-producer-2-build to ip-10-130-137-159.eu-central-1.compute.internal
  Normal  Started    2m17s      kubelet, ip-10-130-137-159.eu-central-1.compute.internal  Started container git-clone
  Normal  AddedInterface  2m17s      multus                Add eth0 [10.124.2.30/23]
  Normal  Pulled    2m17s      kubelet, ip-10-130-137-159.eu-central-1.compute.internal  Container image "quay.io/openshift-release-dev/
....
```

Under the section Log Tail we can see that fetching our private repository failed. This is because we try to fetch the source from a private repository without providing the credentials.


## Fix config

In this step we're going to create a secret for our Git credentials. There are a few different authentication methods [3.4.2. Source Clone Secrets](https://access.redhat.com/documentation/en-us/openshift_container_platform/4.5/html/builds/creating-build-inputs#source-code_creating-build-inputs). For this example we use the Basic Authentication. But instead of a user and password combination we use a username and token credentials.  

To generate a token in the gitea Application, click on the user picture in the top right and then click on "Settings". On the settings page, go to "Applications". It should look like the picture below. Enter a name for your new login token and click "Generate Token". Follow the instruction and copy out the token. It will not be displayed again.

![Generate Application Token in Gitea](../gitea-generate-application-token.png)


Next we create a secret containing our Git credentials. Your username and password will be Base64 encoded and moved from the `stringData` to the `data` section.

{{% alert title="Note" color="primary" %}} Be sure that you replace your \<username> and use your personal access token. {{% /alert %}}

{{< highlight yaml >}}{{< readfile file="manifests/additional/s2i/secret.yaml" >}}{{< /highlight >}}

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/additional/s2i/secret.yaml)

Then we can create the secret

> Replace the token parameter with your newly generated Gitea application token!

```BASH
oc process -f https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/additional/s2i/secret.yaml -p USERNAME=$USER_NAME -p TOKEN=yourToken | oc apply -f -
```

Next we reference the freshly created secret in our BuildConfig. The following command will open the VIM editor ([VIM Cheat Sheet](https://devhints.io/vim)), where you can edit the YAML file directly. As soon you save the file and close the editor, the changes are applied to the resource.

{{% alert title="Note" color="primary" %}}
If you don't like VIM, you can use almost any text editor of your choice. You can control it with the environment variable `KUBE_EDITOR`. Here some examples:  

```bash
export KUBE_EDITOR="atom --wait" # for atom editor  
export KUBE_EDITOR="mate -w" # for textmate  
export KUBE_EDITOR="nano" # for nano  
export KUBE_EDITOR="subl --wait" # sublime  
export KUBE_EDITOR='code --wait' #vsc
```

{{% /alert %}}

```BASH
oc edit buildconfig quarkus-techlab-data-producer
```

As soon the file is open, you can add the highlighted lines below.

{{< highlight yaml "hl_lines=26 27" >}}{{< readfile file="manifests/additional/s2i/buildConfigSecret.yaml" >}}{{< /highlight >}}

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/additional/s2i/buildConfigSecret.yaml)

You can save and close the file, the changes will applied automatically.

Now we can trigger the build again.

```BASH
oc start-build quarkus-techlab-data-producer-s2i
```

You can watch the Build status with following command. You can quit the watch function anytime with `ctrl + c`

```BASH
oc get builds quarkus-techlab-data-producer-s2i-2 -w
```


## Create additional resources

Until now we just created the build resources. Up next is the creation of the DeploymentConfig, Service and the Route.


### DeploymentConfig

{{< highlight yaml >}}{{< readfile file="manifests/additional/s2i/deploymentConfig.yaml" >}}{{< /highlight >}}

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/additional/s2i/deploymentConfig.yaml)

```BASH
oc process -f https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/additional/s2i/deploymentConfig.yaml -p PROJECT_NAME=$PROJECT_NAME | oc apply -f -
```


### Service

{{< highlight yaml >}}{{< readfile file="manifests/additional/s2i/service.yaml" >}}{{< /highlight >}}

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/additional/s2i/service.yaml)

```BASH
oc create -f https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/additional/s2i/service.yaml
```


### Route

{{< highlight yaml >}}{{< readfile file="manifests/additional/s2i/route.yaml" >}}{{< /highlight >}}

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/additional/s2i/route.yaml)

Then we can create the route

```bash
oc process -f https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/additional/s2i/route.yaml -p HOSTNAME=quarkus-techlab-data-producer-s2i-$USER_NAME.{{% param techlabClusterDomainName %}} | oc apply -f -
```

Check if the route was created successfully

```BASH
oc get route quarkus-techlab-data-producer-s2i
```


```
NAME              HOST/PORT                                          PATH   SERVICES          PORT       TERMINATION   WILDCARD
quarkus-techlab-data-producer-s2i   quarkus-techlab-data-producer-s2i-<username>.{{% param techlabClusterDomainName %}}          quarkus-techlab-data-producer-s2i   8080-tcp   edge          None
```

And finally check if you can reach your application within a browser by accessing the public route. `https://quarkus-techlab-data-producer-s2i-<username>.{{% param techlabClusterDomainName %}}`


Do you not find a suitable S2I builder image for you application. [Create your own](https://www.openshift.com/blog/create-s2i-builder-image)
