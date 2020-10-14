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


## Task {{% param sectionnumber %}}.2: Add Resources to a Git repository

As we are proceeding from now on according to the GitOps principle we need to push all existing resources located in `<workspace>/*.yaml`  into a new Git repository.

Create an empty Git repository in Gitea. You will find the exposed hostname of the Gitea repository by inspecting the OpenShift Route:

```bash
oc -n pitc-infra-gitea get route gitea -ojsonpath='{.spec.host}'
```

Enter the Hostname in your browser and register a new account with your personal username and a password that you can remember ;)

![Register new User in Gitea](../gitea-register.png)

Login with the new user and create a new Git repository with the Name `gitops-resources`.

The URL of the newly created Git repository will look like `https://gitea.techlab.openshift.ch/<username>/gitops-resources.git`

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

Ensure that the `USERNAME` environment variable is still present. Set it again if not.

```bash
echo $USERNAME
```

To deploy the resources using the Argo CD CLI use the following command:

```bash
argocd app create argo-$LAB_USER --repo https://gitea.techlab.openshift.ch/$LAB_USER/gitops-resources.git --path $LAB_USER --dest-server https://kubernetes.default.svc --dest-namespace $LAB_USER
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

When there is a new commit in your Git repository, the Argo CD application becomes 'OutOfSync'. Let's assume we want to scale up our producer of the previous lab from 1 to 3 replicas. We will change this in the Deployment.


Do following changes inside your file `<workspace>/producer.yaml`. Change the type to Deployment, remove the annotations, update the selector, change the image to `puzzle/quarkus-techlab-data-producer:kafka` and remove the triggers.

```
{{< highlight YAML "hl_lines=9" >}}
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: data-producer
    application: amm-techlab
  name: data-producer
spec:
  replicas: 3
  selector:
    matchLabels:
      deployment: data-producer
  strategy:
    type: Recreate
...
{{< / highlight >}}
```

Commit the changes and push them to the remote:

```bash
git add . && git commit -m'Scaled up to 3 replicas' && git push
```

Check the state of the resources by cli:

```bash
argocd app get argo-$LAB_USER --refresh
```

The parameter `--refresh` triggers an update against the Git repository. Out of the box Git will be polled by Argo CD. To use a synchronous workflow you can use webhooks in Git. These will trigger a synchronization in Argo CD on every push to the repository.

You will see that the data-producer is OutOfSync:

```
...
GROUP               KIND         NAMESPACE    NAME           STATUS     HEALTH   HOOK  MESSAGE
                    Service      hannelore15  data-producer  Synced     Healthy        service/data-producer unchanged
                    Service      hannelore15  data-consumer  Synced     Healthy        service/data-consumer unchanged
apps                Deployment   hannelore15  data-producer  OutOfSync  Healthy        deployment.apps/data-producer configured
apps                Deployment   hannelore15  data-consumer  Synced     Healthy        deployment.apps/data-consumer unchanged
...
```

When an application is 'OutOfSync' then your deployed 'live state' is no longer the same as the 'target state' which is represented by the resources in the Git repository. You can show the differences between live and target state:

```bash
argocd app diff argo-$LAB_USER
```

which should give you an output similar to:

```bash
===== apps/Deployment hannelore15/data-producer ======
155c155
<   replicas: 1
---
>   replicas: 3
```

Now open the web console of Argo CD and go to your application. The deployment `data-producer` is marked as 'OutOfSync':

![Application Out-of-Sync](../argo-outofsynch.png)

With a click on Deployment -> Diff you will see the differences:

![Application Differences](../argo-diff.png)


Now click `Sync` on the top left and let the magic happens ;) The producer will be scaled up to 3 replicas and the resources are in Sync again.

Double-check the status by cli

```bash
argocd app get argo-$LAB_USER
```

```
...
GROUP               KIND         NAMESPACE    NAME           STATUS  HEALTH       HOOK  MESSAGE
                    Service      hannelore15  data-consumer  Synced  Healthy            service/data-consumer unchanged
                    Service      hannelore15  data-producer  Synced  Healthy            service/data-producer unchanged
apps                Deployment   hannelore15  data-consumer  Synced  Healthy            deployment.apps/data-consumer unchanged
apps                Deployment   hannelore15  data-producer  Synced  Progressing        deployment.apps/data-producer configured
kafka.strimzi.io    Kafka        hannelore15  amm-techlab    Synced                     kafka.kafka.strimzi.io/amm-techlab unchanged
...
```

Argo CD can automatically sync an application when it detects differences between the desired manifests in Git, and the live state in the cluster. A benefit of automatic sync is that CI/CD pipelines no longer need direct access to the Argo CD API server to perform the deployment. Instead, the pipeline makes a commit and push to the Git repository with the changes to the manifests in the tracking Git repo.

To configure automatic sync run (or use the UI):

```bash
argocd app set argo-$LAB_USER --sync-policy automated
```

From now on Argo CD will automatically synchronize resources every time you commit to the Git repository.


## Task {{% param sectionnumber %}}.5: Automatic Self-Healing

By default, changes made to the live cluster will not trigger automatic sync. To enable automatic sync when the live cluster's state deviates from the state defined in Git, run:

```bash
argocd app set argo-$LAB_USER --self-heal
```

Watch the deployment `data-producer` in a separate terminal

```bash
oc get deployment data-producer -w
```

Let's scale our `data-producer` Deployment and observe whats happening:

```bash
oc scale deployment data-producer --replicas=1
```

Argo CD will immediately scale back the `data-producer` Deployment to `3` replicas. You will see the desired replicas count in the watched Deployment.

```
NAME            DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
data-producer   3         3         3         3         51m
data-producer   1         3         3         3         51m
data-producer   1         3         3         3         51m
data-producer   1         1         1         1         51m
data-producer   3         1         1         1         51m
data-producer   3         1         1         1         51m
data-producer   3         1         1         1         51m
data-producer   3         3         3         1         51m
```


## Task {{% param sectionnumber %}}.7: Pruning

TODO


## Task {{% param sectionnumber %}}.8: Additional Task

Setup a new Argo CD application which deployes the Tekton pipelines from the previous lab. You can do it on the web console or by cli.
