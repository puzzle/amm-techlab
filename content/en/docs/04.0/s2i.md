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
* [ ] Welches repository als Source für Si2 verwenden?


## TODO Vorbereitung

* [ ] privates Git Repo mit Sourcen und Deploy Key erstellen
  * Deploy Key zur Verfügung stellen


Source-to-Image (S2I) builds are a special way to inject application source code into a builder image and assembling a new runnable image. There are several builder image available, each for its own framework or language.

The main reasons to use this build strategy are.

* **Speed** - The assemble process where the source code is injected into the image is a single Docker layer. This reduce the build time and resources. Furthermore S2I allows incremental builds.
* **Security** - Dockerfiles are usually running as root and having access to the container network. This is a possible security risk. S2I Images allow more control what permissions and privileges are available to the builder image since the build launches only a single container. OpenShift allows cluster administrator tightly control what privileges developers have at build time.


## Create BuildConfig

First let's create a BuildConfig. The important part in this specification are the source, output and strategy section.

* The source is pointing towards a private Git repository where the source code resides.
* We already discussed the strategy section in the beginning of this chapter. For this example we set the strategy to sourceStrategy (know as Source-to-Image / S2I)
* The last part is the output section. In our example we reference a ImageStreamTag as an output.

```YAML
apiVersion: build.openshift.io/v1
kind: BuildConfig
metadata:
  labels:
    app: spring-boot-s2i
  name: spring-boot-s2i
spec:
  failedBuildsHistoryLimit: 5
  nodeSelector: null
  output:
    to:
      kind: ImageStreamTag
      name: spring-boot-s2i:latest
  postCommit: {}
  resources: {}
  runPolicy: Serial
  source:
    git:
      uri: https://github.com/userXY/spring-boot-private
    type: Git
  strategy:
    sourceStrategy:
      env:
      - name: JAVA_APP_JAR
        value: /tmp/src/build/libs/springboots2idemo-0.1.1-SNAPSHOT.jar
      from:
        kind: ImageStreamTag
        name: openjdk11:latest
    type: Source
  successfulBuildsHistoryLimit: 5
  triggers:
  - github:
      secret: 122hfrCzIb9Ls4q-PLEC
    type: GitHub
  - generic:
      secret: ALAzMOOHHdneC_2cdvV6
    type: Generic
  - type: ConfigChange
  - imageChange:
    type: ImageChange
```

Next we need the definitions for our two ImageStreamTag references.

The first file contains the definitions for the output image.

```YAML
apiVersion: image.openshift.io/v1
kind: ImageStream
metadata:
  labels:
    app: spring-boot-s2i
  name: spring-boot-s2i
spec:
  lookupPolicy:
    local: false
```


In the second file we define S2I builder image. As builder Image we take the `ubi8/openjdk-11` image. This is already prepared for S2I builds.

```YAML
apiVersion: image.openshift.io/v1
kind: ImageStream
metadata:
  labels:
    app: spring-boot-s2i
  name: openjdk11
spec:
  lookupPolicy:
    local: false
  tags:
  - annotations:
      openshift.io/imported-from: registry.redhat.io/ubi8/openjdk-11
    from:
      kind: DockerImage
      name: registry.redhat.io/ubi8/openjdk-11
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
spring-boot-s2i-1   Source   Git           Failed (FetchSourceFailed)    2 minutes ago
```

Now you can see the build failed. Let's figure out why.


## Troubleshooting

First we describe our failed build with following command.

```BASH
oc describe build spring-boot-s2i-1
```

```

We can see the following output (example is truncated)
......

Log Tail:  Cloning "https://github.com/userXY/spring-boot-private" ...
    error: failed to fetch requested repository "https://github.com/userXY/spring-boot-private" with provided credentials
Events:
  Type    Reason    Age      From                Message
  ----    ------    ----      ----                -------
  Normal  Scheduled  2m19s      default-scheduler            Successfully assigned amm-cschlatter/spring-boot-s2i-2-build to ip-10-130-137-159.eu-central-1.compute.internal
  Normal  Started    2m17s      kubelet, ip-10-130-137-159.eu-central-1.compute.internal  Started container git-clone
  Normal  AddedInterface  2m17s      multus                Add eth0 [10.124.2.30/23]
  Normal  Pulled    2m17s      kubelet, ip-10-130-137-159.eu-central-1.compute.internal  Container image "quay.io/openshift-release-dev/
....
```

Under the section Log Tail we can see that fetching our private repository failed. This is because we try to fetch the source from a private repository without providing the credentials.


## Fix config

In this step we're going to create a secret for our Git credentials. There are a few different authentication methods [3.4.2. Source Clone Secrets](https://access.redhat.com/documentation/en-us/openshift_container_platform/4.5/html/builds/creating-build-inputs#source-code_creating-build-inputs). For this example we use the Basic Authentication. But instead of a user and password combination we use a username and token credentials.  
**//TODO: Add how to generate access tokens / or how to get deploy key in GitHub**


First we need our credentials Base64 decoded to use it as a Secret. Let's generate the encoded credentials with following command. Be sure that you replace your username and use your personal access token.

```BASH
echo '<username>' | base64
echo '<token>' | base64
```

Next we create a secret containing our Git credentials.

```YAML
apiVersion: v1
data:
  username: "<Base64 decoded username>"
  password: "<Base64 decoded token>"
kind: Secret
metadata:
  name: git-credentials
type: kubernetes.io/basic-auth
```

Then we can create the secret

```BASH
oc create -f git-credentials.yaml
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
oc edit deploymentconfig spring-boot-s2i
```

As soon the file is open, you can add the highlighted lines below.

```
{{< highlight yaml "hl_lines=21 22" >}}
apiVersion: build.openshift.io/v1
kind: BuildConfig
metadata:
  labels:
    app: spring-boot-s2i
  name: spring-boot-s2i
spec:
  failedBuildsHistoryLimit: 5
  nodeSelector: null
  output:
    to:
      kind: ImageStreamTag
      name: spring-boot-s2i:latest
  postCommit: {}
  resources: {}
  runPolicy: Serial
  source:
    git:
      uri: https://github.com/userXY/spring-boot-private
    type: Git
    sourceSecret:
      name: git-credentials
  strategy:
    sourceStrategy:
      env:
      - name: JAVA_APP_JAR
        value: /tmp/src/build/libs/springboots2idemo-0.1.1-SNAPSHOT.jar
      from:
        kind: ImageStreamTag
        name: openjdk11:latest
    type: Source
  successfulBuildsHistoryLimit: 5
  triggers:
  - github:
      secret: 122hfrCzIb9Ls4q-PLEC
    type: GitHub
  - generic:
      secret: ALAzMOOHHdneC_2cdvV6
    type: Generic
  - type: ConfigChange
  - imageChange:
    type: ImageChange
{{< / highlight >}}
```

You can save and close the file, the changes will applied automatically.

Now we can trigger the build again.

```BASH
oc start-build spring-boot-s2i
```

You can watch the Build status with following command. You can quit the watch function anytime with `ctrl + c`

```BASH
oc get builds spring-boot-s2i-2 -w
```


## Create additional resources

Until now we just created the build resources. Up next is the creation of the DeploymentConfig, Service and the Route.


### DeplyomentConfig

```YAML

apiVersion: apps.openshift.io/v1
kind: DeploymentConfig
metadata:
  labels:
    app: spring-boot-s2i
  name: spring-boot-s2i
spec:
  replicas: 1
  selector:
    deploymentconfig: spring-boot-s2i
  strategy:
    resources: {}
  template:
    metadata:
      labels:
        deploymentconfig: spring-boot-s2i
    spec:
      containers:
      - image: image-registry.openshift-image-registry.svc:5000/amm-userXY/spring-boot-s2i:latest
        name: spring-boot-s2i
        ports:
        - containerPort: 8080
          protocol: TCP
        - containerPort: 8443
          protocol: TCP
        - containerPort: 8778
          protocol: TCP
        resources: {}
  test: false
  triggers:
  - type: ConfigChange
  - imageChangeParams:
      automatic: true
      containerNames:
      - spring-boot-s2i
      from:
        kind: ImageStreamTag
        name: spring-boot-s2i:latest
    type: ImageChange
```


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
    deploymentconfig: spring-boot-s2i
  sessionAffinity: None
  type: ClusterIP
```


### Route


```YAML
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  labels:
    app: spring-boot-s2i
  name: spring-boot-s2i
spec:
  host: spring-boot-s2i-amm-userXY.ocp.aws.puzzle.ch
  port:
    targetPort: 8080-tcp
  tls:
    termination: edge
  to:
    kind: Service
    name: spring-boot-s2i
    weight: 100
  wildcardPolicy: None
```

Check if the route was created successfully

```BASH
oc get oc get route spring-boot-s2i
```


```
NAME              HOST/PORT                                          PATH   SERVICES          PORT       TERMINATION   WILDCARD
spring-boot-s2i   spring-boot-s2i-amm-userXY.ocp.aws.puzzle.ch          spring-boot-s2i   8080-tcp   edge          None
```

And finally check if you can reach your application within a browser  
[https://spring-boot-s2i-amm-userXY.ocp.aws.puzzle.ch](https://spring-boot-s2i-amm-userXY.ocp.aws.puzzle.ch)


Do you not find a suitable S2I builder image for you application. [Create your own](https://www.openshift.com/blog/create-s2i-builder-image).
[S2I Build Strategy](https://docs.openshift.com/container-platform/4.5/builds/build-strategies.html#build-strategy-s2i_build-strategies)
