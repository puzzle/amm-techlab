---
title: "4.2 Argo CD"
linkTitle: "4.2 Argo CD"
weight: 420
sectionnumber: 4.2
description: >
  GitOps with Argo CD.
---


## Introduction to GitOps

{{% alert  color="primary" %}}
[GitOps](https://www.weave.works/technologies/gitops/) is a way to do Kubernetes cluster management and application delivery. It works by using Git as a single source of truth for declarative infrastructure and applications. With GitOps, the use of software agents can alert on any divergence between Git with what's running in a cluster, and if there's a difference, Kubernetes reconcilers automatically update or rollback the cluster depending on the case. With Git at the center of your delivery pipelines, developers use familiar tools to make pull requests to accelerate and simplify both application deployments and operations tasks to Kubernetes.
{{% /alert %}}

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

{{% alert title="Warning" color="secondary" %}}The login with sso does not work in the web ide at the moment. Download the cli locally and process this way.{{% /alert %}}

```bash
argocd login <ARGOCD_SERVER> --sso --grpc-web
```

{{% alert title="Note" color="primary" %}}Follow the sso login steps in the new browser window. The `--grpc-web` parameter is necessary due to missing http 2.0 router.{{% /alert %}}


## Task {{% param sectionnumber %}}.2: Add Resources to a Git Repository

As we are proceeding from now on according to the GitOps principle we need to push all existing Resources located in `<workspace>/*.yaml`  into a new Git Repository.

Create an empty Git Repository in Gitea. You will find the exposed hostname of the Gitea repository by inspecting the OpenShift Route:

```bash
oc -n pitc-infra-gitea get route gitea -ojsonpath='{.spec.host}'
```

Enter the Hostname in your browser and register a new account with your personal username and a password that you can remember ;)

![Register new User in Gitea](../gitea-register.png)

Login with the new user and create a new Git Repository with the Name `gitops-resources`.

The URL of the newly created Git Repository will look like `https://gitea.techlab.openshift.ch/<username>/gitops-resources.git`

![Git repository created](../gitea-repo-created.png)

Change directory to the workspace where the yaml resources of the previous labs are located: `cd <workspace>`

Set your username as an environment variable:

```bash
LAB_USER=<username>
```

Separate the yaml resources by Namespace where they will be deployed to:

```bash
mkdir $LAB_USER
mkdir $LAB_USER-pipelines
mv deploy-pipeline.yaml deploy-tasks.yaml pipeline-resources-template.yaml $LAB_USER-pipelines
mv *.yaml $LAB_USER
```

There should be two directories, one per namespace:

```bash
n8vr6:~/techlab/workspace$ ls -l
total 8
drwxr-sr-x. 2 1000600000 1000600000 4096 Oct 14 12:14 hannelore15
drwxr-sr-x. 2 1000600000 1000600000 4096 Oct 14 12:14 hannelore15-pipelines
```

Configure the Git Client and verify the output

```bash
git config --global user.name "$LAB_USER"
git config --global user.email "foo@bar.org"
git config --global --list
```

Now add the resource definitions to your personal Git repository and push them to remote. Use the password you entered when creating your Gitea user.

```bash
git init
git add --all
git commit -m "Initial commit of resource definitions"
git remote add origin https://$LAB_USER@gitea.techlab.openshift.ch/hannelore15/gitops-resources.git
git push -u origin master
```

After a successful push you should see the following output

```bash
Enumerating objects: 15, done.
Counting objects: 100% (15/15), done.
Delta compression using up to 4 threads
Compressing objects: 100% (15/15), done.
Writing objects: 100% (15/15), 4.02 KiB | 4.02 MiB/s, done.
Total 15 (delta 1), reused 0 (delta 0)
remote: . Processing 1 references
remote: Processed 1 references in total
To https://gitea.techlab.openshift.ch/<username>/gitops-resources.git
 * [new branch]      master -> master
```


## Task {{% param sectionnumber %}}.3: Deploying the resources with Argo CD

Now we want to deploy the resources of the previous labs with Argo CD to demonstrate how Argo CD works.

Ensure that the USERNAME environment variable is still present

```bash
USERNAME=<username>
```

To deploy the resources using the Argo CD CLI use the following command:

```bash
argocd app create argo-$LAB_USER --repo https://gitea.techlab.openshift.ch/$LAB_USER/gitops-resources.git --path $LAB_USER --dest-server https://kubernetes.default.svc --dest-namespace $LAB_USER

argocd app create argo-$LAB_USER-pipelines --repo https://gitea.techlab.openshift.ch/$LAB_USER/gitops-resources.git --path $LAB_USER-pipelines --dest-server https://kubernetes.default.svc --dest-namespace $LAB_USER-pipelines
```

{{% alert title="Note" color="primary" %}}If you want to deploy it in a different namespace, make sure the namespaces exists before synching the app{{% /alert %}}

Once the application is created, you can view its status:

```bash
argocd app get argo-$LAB_USER
```

```
Name:               argo-hannelore15
Project:            default
Server:             https://kubernetes.default.svc
Namespace:          hannelore15
URL:                https://argocd.techlab.openshift.ch/applications/argo-hannelore15
Repo:               https://gitea.techlab.openshift.ch/hannelore15/gitops-resources.git
Target:
Path:               hannelore15
SyncWindow:         Sync Allowed
Sync Policy:        <none>
Sync Status:        OutOfSync from  (3da0af3)
Health Status:      Missing

GROUP               KIND              NAMESPACE    NAME           STATUS     HEALTH   HOOK  MESSAGE
                    DeploymentConfig  hannelore15  data-producer  OutOfSync  Missing
                    Route             hannelore15  data-consumer  OutOfSync  Missing
                    Service           hannelore15  data-consumer  OutOfSync  Healthy
                    Service           hannelore15  data-producer  OutOfSync  Healthy
apps                Deployment        hannelore15  data-consumer  OutOfSync  Healthy
build.openshift.io  BuildConfig       hannelore15  data-producer  OutOfSync
image.openshift.io  ImageStream       hannelore15  data-producer  OutOfSync
kafka.strimzi.io    Kafka             hannelore15  amm-techlab    OutOfSync
kafka.strimzi.io    KafkaTopic        hannelore15  manual         OutOfSync
route.openshift.io  Route             hannelore15  data-producer  OutOfSync
```

The application status is initially in 'OutOfSync' state since the application has yet to be deployed and no Kubernetes resources have been created. To sync (deploy) the application, run:

```bash
argocd app sync argo-$LAB_USER
```

This command retrieves the manifests from the repository and performs a `kubectl apply` of the manifests. The example app is now running and you can now view its resource components, logs, events, and assessed health status.

Check the Argo CD UI to browse the application and their components:

![Argo CD App overview](../argo-app.png)

![Application Tree](../argo-tree.png)

Or use the CLI:

```bash
argocd app get argo-$LAB_USER
```

which gives you an output similar to this:

```
Name:               argo-hannelore15
Project:            default
Server:             https://kubernetes.default.svc
Namespace:          hannelore15
URL:                https://argocd.techlab.openshift.ch/applications/argo-hannelore15
Repo:               https://gitea.techlab.openshift.ch/hannelore15/gitops-resources.git
Target:
Path:               hannelore15
SyncWindow:         Sync Allowed
Sync Policy:        <none>
Sync Status:        Synced to  (d3d16b3)
Health Status:      Healthy

GROUP               KIND              NAMESPACE    NAME           STATUS  HEALTH   HOOK  MESSAGE
                    Service           hannelore15  data-consumer  Synced  Healthy        service/data-consumer created
                    Service           hannelore15  data-producer  Synced  Healthy        service/data-producer created
apps                Deployment        hannelore15  data-consumer  Synced  Healthy        deployment.apps/data-consumer created
kafka.strimzi.io    Kafka             hannelore15  amm-techlab    Synced                 kafka.kafka.strimzi.io/amm-techlab created
route.openshift.io  Route             hannelore15  data-consumer  Synced                 route.route.openshift.io/data-consumer created
image.openshift.io  ImageStream       hannelore15  data-producer  Synced                 imagestream.image.openshift.io/data-producer created
route.openshift.io  Route             hannelore15  data-producer  Synced                 route.route.openshift.io/data-producer created
build.openshift.io  BuildConfig       hannelore15  data-producer  Synced                 buildconfig.build.openshift.io/data-producer created
apps.openshift.io   DeploymentConfig  hannelore15  data-producer  Synced                 deploymentconfig.apps.openshift.io/data-producer created
kafka.strimzi.io    KafkaTopic        hannelore15  manual         Synced                 kafkatopic.kafka.strimzi.io/manual created
```

So now, all resources are in-sync and managed by Argo CD. If the deployed resources had the same state as the resources pushed to git, no new version of them has been deployed.


## Task {{% param sectionnumber %}}.4: Automated Sync Policy and Diff

When there is a new commit in your Git Repository, the Argo CD Application becomes 'OutOfSync' again. To simulate a change (because we don't have control over the Argo CD repository) in your application lets manually change our Deployment, e.g. scale your `example-php-docker-helloworld` Deployment to 2:

```bash
oc scale deployment example-php-docker-helloworld --replicas=2
```

Check the application status with:

![Application Out-of-Sync](../argo-outofsynch.png)

which should show that the application is 'OutOfSync'. This means your 'live state' is not the same as the 'target state' from the Git repository. the `argocd app get argo-example-<username>`

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

As you see, your `example-php-docker-helloworld` Deployment resource is 'OutOfSync'. You can perform a diff against the target and live state using:

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

Argo CD can automatically sync an application when it detects differences between the desired manifests in Git, and the live state in the cluster. A benefit of automatic sync is that CI/CD pipelines no longer need direct access to the Argo CD API server to perform the deployment. Instead, the pipeline makes a commit and push to the Git repository with the changes to the manifests in the tracking Git repo.

To configure automatic sync run (or use the UI):

```bash
argocd app set argo-example-<username> --sync-policy automated
```

and now everytime you create a new commit in your Git Repository, Argo CD will automaticly perform a sync of your application.


## Task {{% param sectionnumber %}}.3: Automatic Self-Healing

By default, changes made to the live cluster will not trigger automatic sync. To enable automatic sync when the live cluster's state deviates from the state defined in Git, run:

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

You've now learned the basic functionality of argocd, as an additional lab you can now:

* Fork the git repository with the k8s manifests <https://github.com/puzzle/amm-argocd-example.git>
  * Use the Gitea Server (URL provided by trainer, register and login with your username and password) or your personal Github Account
* create a new argocd app using the new git repository
* create a route resource YAML which exposes the example application
* push it to your git repository
* and let the magic happen
