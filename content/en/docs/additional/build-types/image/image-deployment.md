---
title: "9.2.4 Image Deployment"
linkTitle: "Image Deployment"
weight: 924
sectionnumber: 9.2.4
description: >
  Container Image Deployment.
---


## {{% param sectionnumber %}}.1 Lab

<!--
## TODO Lab

* [ ] keine Buildconfig sondern direkt DeploymentConfig und ImageStream
* Beschreiben: Imagestream und polling / scheduling von neuen Images, damit image stream trigger funktioniert.
* Hinweis: per Default polling nur für latest Tag
* Beschreiben: Private Registry wie und wo muss man das pull secret angeben.
-->

In this section we cover how to deploy an existing Docker Image from an private image registry. Besides we show how to create a ImageStream to track changes on the deployed image and trigger an update on the deployment.

Let's start with the deployment configuration

{{< highlight yaml >}}{{< readfile file="content/en/docs/additional/build-types/image/deploymentConfig.yaml" >}}{{< /highlight >}}

[Source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/content/en/docs/additional/build-types/image/deploymentConfig.yaml)

```BASH
oc create -f https://raw.githubusercontent.com/puzzle/amm-techlab/master/content/en/docs/additional/build-types/image/deploymentConfig.yaml
```

Next we create the ImageStream definition. The important part is under the `tags` section. There we define a reference to an external Docker registry and define which image to track. Another important field is the import policy. If you query an image from an external registry, you can set scheduled import to true.

{{< highlight yaml >}}{{< readfile file="content/en/docs/additional/build-types/image/imageStream.yaml" >}}{{< /highlight >}}

[Source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/content/en/docs/additional/build-types/image/imageStream.yaml)

```BASH
oc create -f https://raw.githubusercontent.com/puzzle/amm-techlab/master/content/en/docs/additional/build-types/image/imageStream.yaml
```


### Credentials

In this section we create a docker secret to access the private registry and pull the docker image.

```BASH
oc create secret docker-registry regcred --docker-server=<registry_server> --docker-username=<username> --docker-password=<password> --docker-email=<email>
```

Next we link the secret with our default service account.

```BASH
oc secrets link default regcred --for=pull
```
