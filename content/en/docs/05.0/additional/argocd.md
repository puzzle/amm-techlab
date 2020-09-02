---
title: "5.5.2 Argo CD"
linkTitle: "Argo CD"
weight: 552
sectionnumber: 5.5.2
description: >
  GitOps with Argo CD.
---


## TODO

* [ ] Testen und durchspielen
* [ ] ev. auf example spring boot app Umbauen


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

Let's start by downloading the latest Argo CD version from <https://github.com/argoproj/argo-cd/releases/latest>. More detailed installation instructions can be found via the [CLI installation documentation](https://argoproj.github.io/argo-cd/cli_installation/).

You can access Argo CD via UI or using the CLI. For CLI usage use the following command to login (credentials are given by your teacher):

```bash
argocd login <ARGOCD_SERVER> --sso --grpc-web
```

{{% alert title="Note" color="primary" %}}Follow the sso login steps in the new browser window. The `--grpc-web` parameter is necessary due to missing http 2.0 router.{{% /alert %}}


## Task {{% param sectionnumber %}}.2: Create an Application

An example repository containing a guestbook application is available at <https://github.com/argoproj/argocd-example-apps.git> to demonstrate how Argo CD works.

To deploy this application using the Argo CD CLI use the following command:

```bash
argocd app create guestbook-<username> --repo https://github.com/argoproj/argocd-example-apps.git --path guestbook --dest-server https://kubernetes.default.svc --dest-namespace <username>-argocd
```

Once the guestbook application is created, you can now view its status:

```bash
argocd app get guestbook-<username>
```

```
Name:               guestbook-<username>
Server:             https://kubernetes.default.svc
Namespace:          <username>-argocd
URL:                https://<ARGOCD_SERVER>/applications/guestbook
Repo:               https://github.com/argoproj/argocd-example-apps.git
Target:
Path:               guestbook
Sync Policy:        <none>
Sync Status:        OutOfSync from  (1ff8a67)
Health Status:      Missing

GROUP  KIND        NAMESPACE  NAME      STATUS     HEALTH
apps   Deployment  <username>-argocd    guestbook-ui  OutOfSync  Missing
       Service     <username>-argocd    guestbook-ui  OutOfSync  Missing
```

The application status is initially in OutOfSync state since the application has yet to be deployed and no Kubernetes resources have been created. To sync (deploy) the application, run:

```bash
argocd app sync guestbook-<username>
```

This command retrieves the manifests from the repository and performs a `kubectl apply` of the manifests. The guestbook app is now running and you can now view its resource components, logs, events, and assessed health status.

Check the ArgoCD UI application:

![Guestbook App](../guestbook-app.png)

![Guestbook Tree](../guestbook-tree.png)

Or use the CLI:

```bash
argocd app get guestbook-<username>
```

which gives you an output similar to this:

```

Name:               guestbook-<username>
Server:             https://kubernetes.default.svc
Namespace:          <username>-argocd
URL:                https://<ARGOCD_SERVER>/applications/guestbook
Repo:               https://github.com/argoproj/argocd-example-apps.git
Target:
Path:               guestbook
Sync Policy:        <none>
Sync Status:        Synced to HEAD (6bed858)
Health Status:      Healthy

GROUP  KIND        NAMESPACE            NAME          STATUS  HEALTH
apps   Deployment  <username>-argocd    guestbook-ui  Synced  Healthy
       Service     <username>-argocd    guestbook-ui  Synced  Healthy
```

So the application is synced now and a Kubernetes Deployment and a Kubernetes Service was created. You can check this with:

```bash
oc get all
```

```
NAME                                READY   STATUS    RESTARTS   AGE
pod/guestbook-ui-85c9c5f9cb-v4x5p   1/1     Running   0          61m

NAME                   TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
service/guestbook-ui   ClusterIP   10.43.169.62   <none>        80/TCP    62m

NAME                           READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/guestbook-ui   1/1     1            1           61m

NAME                                      DESIRED   CURRENT   READY   AGE
replicaset.apps/guestbook-ui-85c9c5f9cb   1         1         1       61m
```


## Task {{% param sectionnumber %}}.3: Automated Sync Policy and Diff

When there is a new commit in your Git Repository, the Argo CD Application becomes OutOfSync again. To simulate a change (because we don't have controll over the Argo CD repository) in your application, lets manually change our Deployment, e.g. scale your `guestbook-ui` Deployment to 2:

```bash
oc scale deployment guestbook-ui --replicas=2
```

Check the application status with:

![Application Out-of-Sync](../argocd_outofsync.png)

which should show that the application is OutOfSync. This means you live state is not the same as the target state from the Git repository. the `argocd app get guestbook-<username>`

```bash
Name:               guestbook-<username>
Project:            default
Server:             https://kubernetes.default.svc
Namespace:          guestbook-<username>
URL:                https://<ARGOCD_SERVER>/applications/guestbook
Repo:               https://github.com/argoproj/argocd-example-apps.git
Target:             HEAD
Path:               guestbook
SyncWindow:         Sync Allowed
Sync Policy:        Automated
Sync Status:        OutOfSync from HEAD (6bed858)
Health Status:      Healthy

GROUP  KIND        NAMESPACE             NAME          STATUS     HEALTH   HOOK  MESSAGE
apps   Deployment  guestbook-<username>  guestbook-ui  OutOfSync  Healthy        deployment.apps/guestbook-ui configured
       Service     guestbook-<username>  guestbook-ui  Synced     Healthy
```

As you see, your `guestbook-ui` Deployment resource is OutOfSync. You can perform a diff against the target and live state using:

```bash
argocd app diff guestbook-<username>
```

which should give you an output similar to:

```bash
===== apps/Deployment guestbook-<username>/guestbook-ui ======
8c8
<   replicas: 2
---
>   replicas: 1
```

Which is the change we simulated by scaling our Deployment.

With:

```bash
argocd app sync guestbook-<username>
```

you can sync your application again against the target state.

Argo CD has the ability to automatically sync an application when it detects differences between the desired manifests in Git, and the live state in the cluster. A benefit of automatic sync is that CI/CD pipelines no longer need direct access to the Argo CD API server to perform the deployment. Instead, the pipeline makes a commit and push to the Git repository with the changes to the manifests in the tracking Git repo.

To configure automated sync run (or use the UI):

```bash
argocd app set guestbook-<username> --sync-policy automated
```

and now everytime you create a new commit in your Git Repository, Argo CD will automaticly perform a sync of your application.


## Task {{% param sectionnumber %}}.3: Automatic Self-Healing

By default, changes that are made to the live cluster will not trigger automated sync. To enable automatic sync when the live cluster's state deviates from the state defined in Git, run:

```bash
argocd app set guestbook-<username> --self-heal
```

Let's scale our `guestbook-ui` Deployment and observe whats happening:

```bash
oc scale deployment guestbook-ui --replicas=2
```

Argo CD will immediatly scale back the `guestbook-ui` Deployment to `1` replica. You can verify this with:

```bash
oc get deployment guestbook-ui
```

```
NAME           READY   UP-TO-DATE   AVAILABLE   AGE
guestbook-ui   1/1     1            1           22m
```

