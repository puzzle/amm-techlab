---
title: "2.2 Configure the application"
linkTitle: "2.2 Configure the application"
weight: 22
sectionnumber: 2.2
description: >
  Configure the application based on environment variables.
---

In this stage, we show you how to configure your application.
For this lab the application of the previous lab is used.


## Task {{% param sectionnumber %}}.1: Update application port inside deployment

We will change the port of the application. With this change we need to adapt the deployment first. There are three ports to change. The container port itself, and the ports for the liveness/readiness probes.

<!-- TODO fix and add highlight again: "hl_lines=29 38 45" -->
{{< readfile file="/manifests/02.0/2.1/producer.yaml" code="true" lang="yaml" >}}

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/main/manifests/02.0/2.1/producer.yaml)

Update the application port from 8080 to 8081 using `oc patch`:

```BASH
oc patch dc/data-producer --type "json" -p '[{"op":"replace","path":"/spec/template/spec/containers/0/ports/0/containerPort","value":8081}]'
```

```
deploymentconfig.apps.openshift.io/data-producer patched
```

Update also the ports of the liveness and readiness probes from 8080 to 8081 using `oc patch`:

{{% details title="command hint" mode-switcher="normalexpertmode" %}}

```BASH

oc patch dc/data-producer --type "json" -p '[{"op":"replace","path":"/spec/template/spec/containers/0/livenessProbe/httpGet/port","value":8081}]'
oc patch dc/data-producer --type "json" -p '[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/port","value":8081}]'

```

{{% /details %}}

{{% alert title="Note" color="primary" %}} The changed DeploymentConfig should now represent the [solution](https://raw.githubusercontent.com/puzzle/amm-techlab/main/manifests/02.0/2.2/producer.yaml) {{% /alert %}}

Verify the changed port of the pod by describing the DeploymentConfig using `oc describe`.

{{% details title="command hint" mode-switcher="normalexpertmode" %}}

```BASH
oc describe deploymentconfig data-producer
```

{{% /details %}}

> The pod does not start because that the readiness probe fails. Now we have to change the application to use the port 8081 for serving its endpoint.


## Task {{% param sectionnumber %}}.2: Configure application

There are several options how to configure a Quarkus application. We'll show how to do it with environment variables. You can overwrite every property in the `application.properties` file with the corresponding environment variable. (eg. `quarkus.http.port=8081` in the application.properties is the same like `QUARKUS_HTTP_PORT=8081` as an environment variable) [Quarkus: overriding-properties-at-runtime](https://quarkus.io/guides/config#overriding-properties-at-runtime)

The environment of the DeploymentConfig has to be extended with a new environment variable named `QUARKUS_HTTP_PORT`.

First, let's check the environment:

```BASH
oc set env dc/data-producer --list
```

```
# deploymentconfigs/data-producer, container data-producer
```

There are no environment variables configured.

Add the environment variable `QUARKUS_HTTP_PORT` with the value 8081 with `oc set env`.

{{% details title="command hint" mode-switcher="normalexpertmode" %}}

```BASH
oc set env dc/data-producer QUARKUS_HTTP_PORT=8081
```

```
deploymentconfig.apps.openshift.io/data-producer updated
```

{{% /details %}}

The variable should be configured now. Check it by listing the environment of the DeploymentConfig again.

{{% details title="command hint" mode-switcher="normalexpertmode" %}}

```BASH
oc set env dc/data-producer --list
```

{{% /details %}}

Expected output of the environment listing:

```
# deploymentconfigs/data-producer, container data-producer
QUARKUS_HTTP_PORT=8081
```


## Task {{% param sectionnumber %}}.3: Verify application

Changing the environment of a deployment triggers a rollout of the application pod.
After the container has started successfully, the application should be reachable again.

Check if the changes were applied correctly. Open your browser and navigate to your application:
`https://data-producer-<username>.{{% param techlabClusterDomainName %}}/data`

{{% alert  color="primary" %}}Replace **\<username>** with your username!{{% /alert %}}


## Important notes

We showed how to change the OpenShift resources using the commands `oc patch` and `oc set env`.
This is good for developing or debugging the setup of an application project.

For changing stages and productive environments, we propose updating the YAML representations inside the Git repository and apply the files again.


## Solution

The needed resource files are available inside the folder [manifests/02.0/2.2/](https://github.com/puzzle/amm-techlab/tree/master/manifests/02.0/2.2/) of the techlab [github repository](https://github.com/puzzle/amm-techlab).

If you weren't successful, you can update your project with the solution by cloning the Techlab Repository `git clone https://github.com/puzzle/amm-techlab.git` and executing this command:

```BASH
oc apply -f manifests/02.0/2.2/
```
