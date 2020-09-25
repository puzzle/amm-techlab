---
title: "4.2 Argo CD"
linkTitle: "4.2 Argo CD"
weight: 420
sectionnumber: 4.2
description: >
  GitOps with Argo CD.
---


## Introduction to GitOps

> [GitOps](https://www.weave.works/technologies/gitops/) is a way to do Kubernetes cluster management and application delivery.  It works by using Git as a single source of truth for declarative infrastructure and applications. With GitOps, the use of software agents can alert on any divergence between Git with what's running in a cluster, and if there's a difference, Kubernetes reconcilers automatically update or rollback the cluster depending on the case. With Git at the center of your delivery pipelines, developers use familiar tools to make pull requests to accelerate and simplify both application deployments and operations tasks to Kubernetes.

Argo CD is a declarative, GitOps continuous delivery tool for Kubernetes.

Argo CD follows the GitOps pattern of using Git repositories as the source of truth for defining the desired application state. Kubernetes manifests can be specified in several ways:

* [kustomize](https://kustomize.io/) applications
* [helm](https://helm.sh/) charts
* [ksonnet](https://github.com/ksonnet/ksonnet) applications
* [jsonnet](https://jsonnet.org/) files
* Plain directory of YAML/json manifests
* Any custom config management tool configured as a config management plugin

Argo CD automates the deployment of the desired application states in the specified target environments. Application deployments can track updates to branches, tags, or pinned to a specific version of manifests at a Git commit. See tracking strategies for additional details about the different tracking strategies available.

For a quick 10 minute overview of Argo CD, check out the demo presented to the Sig Apps community meeting:

{{< youtube aWDIQMbp1cc >}}


## Task {{% param sectionnumber %}}.1: Getting started

Let's start by downloading the latest Argo CD version from <https://github.com/argoproj/argo-cd/releases/latest>. More detailed installation instructions can be found via the [CLI installation documentation](https://argoproj.github.io/argo-cd/cli_installation/). The cli is already installed in the Web IDE.

You can access Argo CD via UI or using the CLI. For CLI usage use the following command to login (credentials are given by your teacher):

```bash
argocd login <ARGOCD_SERVER> --sso --grpc-web
```

{{% alert title="Note" color="primary" %}}Follow the sso login steps in the new browser window. The `--grpc-web` parameter is necessary due to missing http 2.0 router.{{% /alert %}}

{{% alert title="Warning" color="secondary" %}}The login with sso does not work in the web ide at the moment. Download the cli locally and process this way.{{% /alert %}}


## Task {{% param sectionnumber %}}.2: Create an Application

An example repository containing the appuio example application is available at <https://github.com/puzzle/amm-argocd-example.git> to demonstrate how Argo CD works.

To deploy this application using the Argo CD CLI use the following command:

```bash
argocd app create argo-example-<username> --repo https://github.com/puzzle/amm-argocd-example.git --path example-app --dest-server https://kubernetes.default.svc --dest-namespace <username>
```

{{% alert title="Note" color="primary" %}}If you want to deploy it in a different namespace, make sure the namespaces exists before synching the app{{% /alert %}}

Once the application is created, you can now view its status:

```bash
argocd app get argo-example-<username>
```

```
Name:               argo-example-<username>
Project:            default
Server:             https://kubernetes.default.svc
Namespace:          <username>
URL:                https://argo.techlab.openshift.ch/applications/argo-example-hannelore15
Repo:               https://github.com/puzzle/amm-argocd-example.git
Target:
Path:               example-app
SyncWindow:         Sync Allowed
Sync Policy:        <none>
Sync Status:        Synced to  (eb54f2e)
Health Status:      Healthy

GROUP  KIND        NAMESPACE    NAME                           STATUS     HEALTH   HOOK  MESSAGE
       Service     hannelore15  example-php-docker-helloworld  OutOfSync  Missing
apps   Deployment  hannelore15  example-php-docker-helloworld  OutOfSync  Missing
```

The application status is initially in OutOfSync state since the application has yet to be deployed and no Kubernetes resources have been created. To sync (deploy) the application, run:

```bash
argocd app sync argo-example-<username>
```

This command retrieves the manifests from the repository and performs a `kubectl apply` of the manifests. The example app is now running and you can now view its resource components, logs, events, and assessed health status.

Check the ArgoCD UI application:

![Guestbook App](../argo-app.png)

![Guestbook Tree](../argo-tree.png)

Or use the CLI:

```bash
argocd app get argo-example-<username>
```

which gives you an output similar to this:

```

Name:               argo-example-<username>
Server:             https://kubernetes.default.svc
Namespace:          <username>-argocd
URL:                https://<ARGOCD_SERVER>/applications/argo-example
Repo:               https://github.com/puzzle/amm-argocd-example.git
Target:
Path:               example-app
Sync Policy:        <none>
Sync Status:        Synced to HEAD (6bed858)
Health Status:      Healthy

GROUP  KIND        NAMESPACE            NAME                           STATUS  HEALTH
apps   Deployment  <username>           example-php-docker-helloworld  Synced  Healthy
       Service     <username>           example-php-docker-helloworld  Synced  Healthy
```

So the application is synced now and a Kubernetes Deployment and a Kubernetes Service was created. You can check this with:

```bash
oc get all
```

```
NAME                                                 READY   STATUS    RESTARTS   AGE
pod/example-php-docker-helloworld-85c9c5f9cb-v4x5p   1/1     Running   0          61m

NAME                                    TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
service/example-php-docker-helloworld   ClusterIP   10.43.169.62   <none>        80/TCP    62m

NAME                                            READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/example-php-docker-helloworld   1/1     1            1           61m

NAME                                                       DESIRED   CURRENT   READY   AGE
replicaset.apps/example-php-docker-helloworld-85c9c5f9cb   1         1         1       61m
```


## Task {{% param sectionnumber %}}.3: Automated Sync Policy and Diff

When there is a new commit in your Git Repository, the Argo CD Application becomes OutOfSync again. To simulate a change (because we don't have control over the Argo CD repository) in your application, lets manually change our Deployment, e.g. scale your `example-php-docker-helloworld` Deployment to 2:

```bash
oc scale deployment example-php-docker-helloworld --replicas=2
```

Check the application status with:

![Application Out-of-Sync](../argo-outofsynch.png)

which should show that the application is OutOfSync. This means you live state is not the same as the target state from the Git repository. the `argocd app get argo-example-<username>`

```bash
Name:               argo-example-<username>
Project:            default
Server:             https://kubernetes.default.svc
Namespace:          <username>
URL:                https://argo.techlab.openshift.ch/applications/argo-example-hannelore15
Repo:               https://github.com/puzzle/amm-argocd-example.git
Target:
Path:               example-app
SyncWindow:         Sync Allowed
Sync Policy:        <none>
Sync Status:        OutOfSync from  (eb54f2e)
Health Status:      Healthy

GROUP  KIND        NAMESPACE    NAME                           STATUS     HEALTH   HOOK  MESSAGE
       Service     <username>   example-php-docker-helloworld  Synced     Healthy        service/example-php-docker-helloworld created
apps   Deployment  <username>   example-php-docker-helloworld  OutOfSync  Healthy        deployment.apps/example-php-docker-helloworld created
```

As you see, your `example-php-docker-helloworld` Deployment resource is OutOfSync. You can perform a diff against the target and live state using:

```bash
argocd app diff argo-example-<username>
```

which should give you an output similar to:

```bash
===== apps/Deployment argo-example-<username>/example-php-docker-helloworld ======
8c8
<   replicas: 2
---
>   replicas: 1
```

Which is the change we simulated by scaling our Deployment.

With:

```bash
argocd app sync argo-example-<username>
```

you can sync your application again against the target state.

Argo CD has the ability to automatically sync an application when it detects differences between the desired manifests in Git, and the live state in the cluster. A benefit of automatic sync is that CI/CD pipelines no longer need direct access to the Argo CD API server to perform the deployment. Instead, the pipeline makes a commit and push to the Git repository with the changes to the manifests in the tracking Git repo.

To configure automated sync run (or use the UI):

```bash
argocd app set argo-example-<username> --sync-policy automated
```

and now everytime you create a new commit in your Git Repository, Argo CD will automaticly perform a sync of your application.


## Task {{% param sectionnumber %}}.3: Automatic Self-Healing

By default, changes that are made to the live cluster will not trigger automated sync. To enable automatic sync when the live cluster's state deviates from the state defined in Git, run:

```bash
argocd app set argo-example-<username> --self-heal
```

Let's scale our `example-php-docker-helloworld` Deployment and observe whats happening:

```bash
oc scale deployment example-php-docker-helloworld --replicas=2
```

Argo CD will immediatly scale back the `example-php-docker-helloworld` Deployment to `1` replica. You can verify this with:

```bash
oc get deployment example-php-docker-helloworld
```

```
NAME                            READY   UP-TO-DATE   AVAILABLE   AGE
example-php-docker-helloworld   1/1     1            1           22m
```


## Task {{% param sectionnumber %}}.4: Additional Task

You now learnt the basic functionality of argocd, as an additional lab you can now:

* Fork the git repository with the k8s manifests <https://github.com/puzzle/amm-argocd-example.git>
* create a new argocd app using the new git repository
* create a route resource yaml which exposes the example application
* push it to your git repository
* and let the magic happen
