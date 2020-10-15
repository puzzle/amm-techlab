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

As we are proceeding from now on according to the GitOps principle we need to push all existing resources located in `<workspace>/*.yaml`  into a new Git repository. All the cli commands in this chapter must be executed in the terminal of the provided Web IDE.

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

Go back to the webinterface of Gitea and inspect the structure and files in your personal Git repository: `https://gitea.techlab.openshift.ch/<username>/gitops-resources`


## Task {{% param sectionnumber %}}.3: Deploying the resources with Argo CD

Now we want to deploy the resources of the previous labs with Argo CD to demonstrate how Argo CD works.

{{% alert title="Warning" color="secondary" %}}All steps which includes the argocd cli tool, must be executed on the local machine. This is due to the sso login in the web ide does not work at the moment. {{% /alert %}}

Ensure that the `LAB_USER` environment variable is still present. Set it again if not.

```bash
echo $LAB_USER
```

Change to your main Project.

```bash
oc project $LAB_USER
```

To deploy the resources using the Argo CD CLI use the following command:

```bash
argocd app create argo-$LAB_USER --repo https://gitea.techlab.openshift.ch/$LAB_USER/gitops-resources.git --path $LAB_USER --dest-server https://kubernetes.default.svc --dest-namespace $LAB_USER
```

{{% alert title="Note" color="primary" %}}We don't need to provide Git credentials because the repository is readable for non-authenticated users as well{{% /alert %}}

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
Sync Status:        OutOfSync from  (fe4e2b6)
Health Status:      Healthy

GROUP               KIND         NAMESPACE    NAME           STATUS     HEALTH   HOOK  MESSAGE
                    Service      hannelore15  data-consumer  OutOfSync  Healthy
                    Service      hannelore15  data-producer  OutOfSync  Healthy
apps                Deployment   hannelore15  data-consumer  OutOfSync  Healthy
apps                Deployment   hannelore15  data-producer  OutOfSync  Healthy
build.openshift.io  BuildConfig  hannelore15  data-producer  OutOfSync
image.openshift.io  ImageStream  hannelore15  data-producer  OutOfSync
kafka.strimzi.io    Kafka        hannelore15  amm-techlab    OutOfSync
kafka.strimzi.io    KafkaTopic   hannelore15  manual         OutOfSync
route.openshift.io  Route        hannelore15  data-consumer  OutOfSync
route.openshift.io  Route        hannelore15  data-producer  OutOfSync
```

The application status is initially in OutOfSync state. To sync (deploy) the resource manifests, run:

```bash
argocd app sync argo-$LAB_USER
```

This command retrieves the manifests from the git repository and performs a `kubectl apply` on them. Because all our manifests has been deployed manually before, no new rollout of them will be triggered on OpenShift. But form now on, all resources are managed by Argo CD. Congrats, the first step in direction GitOps! :)


Check the Argo CD UI to browse the application and their components. The URL of the Argo CD webinterface will be provided by the teacher.

![Argo CD App overview](../argo-app.png)

![Application Tree](../argo-tree.png)


Or use the CLI to check the state of the Argo CD application:

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
Sync Status:        Synced to  (fe4e2b6)
Health Status:      Healthy

GROUP               KIND         NAMESPACE    NAME           STATUS  HEALTH   HOOK  MESSAGE
                    Service      hannelore15  data-producer  Synced  Healthy        service/data-producer configured
                    Service      hannelore15  data-consumer  Synced  Healthy        service/data-consumer configured
apps                Deployment   hannelore15  data-consumer  Synced  Healthy        deployment.apps/data-consumer configured
apps                Deployment   hannelore15  data-producer  Synced  Healthy        deployment.apps/data-producer configured
kafka.strimzi.io    Kafka        hannelore15  amm-techlab    Synced                 kafka.kafka.strimzi.io/amm-techlab configured
route.openshift.io  Route        hannelore15  data-consumer  Synced                 route.route.openshift.io/data-consumer configured
route.openshift.io  Route        hannelore15  data-producer  Synced                 route.route.openshift.io/data-producer configured
image.openshift.io  ImageStream  hannelore15  data-producer  Synced                 imagestream.image.openshift.io/data-producer configured
build.openshift.io  BuildConfig  hannelore15  data-producer  Synced                 buildconfig.build.openshift.io/data-producer configured
kafka.strimzi.io    KafkaTopic   hannelore15  manual         Synced                 kafkatopic.kafka.strimzi.io/manual configured
```


## Task {{% param sectionnumber %}}.4: Automated Sync Policy and Diff

When there is a new commit in your Git repository, the Argo CD application becomes OutOfSync. Let's assume we want to scale up our producer of the previous lab from 1 to 3 replicas. We will change this in the Deployment.

Change the number of replicas in your file `<workspace>/producer.yaml`.

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

Don't forget to interactively provide your personal Git password. After a successful push you should see a message similar to the following lines:

```
[master 18daed3] Scaled up to 3 replicas
 1 file changed, 1 insertion(+), 1 deletion(-)
Enumerating objects: 7, done.
Counting objects: 100% (7/7), done.
Delta compression using up to 4 threads
Compressing objects: 100% (4/4), done.
Writing objects: 100% (4/4), 372 bytes | 372.00 KiB/s, done.
Total 4 (delta 2), reused 0 (delta 0)
remote: . Processing 1 references
remote: Processed 1 references in total
To https://gitea.techlab.openshift.ch/hannelore15/gitops-resources.git
   fe4e2b6..18daed3  master -> master
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

When an application is OutOfSync then your deployed 'live state' is no longer the same as the 'target state' which is represented by the resource manifests in the Git repository. You can inspect the differences between live and target state by cli:

```bash
argocd app diff argo-$LAB_USER
```

which should give you an output similar to:

```
===== apps/Deployment hannelore15/data-producer ======
155c155
<   replicas: 1
---
>   replicas: 3
```

Now open the web console of Argo CD and go to your application. The deployment `data-producer` is marked as 'OutOfSync':

![Application Out-of-Sync](../argo-outofsynch.png)

With a click on Deployment > Diff you will see the differences:

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

You probably asked yourself how can I delete deployed resources on the container platform? Argo CD can be configured to delete resources that no longer exist in the Git repository.

First delete the file `imageStream.yaml` from Git repository and push the changes

```bash
git rm $LAB_USER/imageStream.yaml
git add --all && git commit -m'Removes ImageStream' && git push
```

Check the status of the application with

```bash
argocd app get argo-$LAB_USER --refresh
```

You will see that even with auto-sync and self-healing enabled the status is still OutOfSync

```
GROUP               KIND         NAMESPACE    NAME           STATUS     HEALTH   HOOK  MESSAGE
...
build.openshift.io  BuildConfig  hannelore15  data-producer  Synced                    
image.openshift.io  ImageStream  hannelore15  data-producer  OutOfSync                 
kafka.strimzi.io    Kafka        hannelore15  amm-techlab    Synced                    
...
```

Now enable the auto pruning explicitly:

```bash
argocd app set argo-$LAB_USER --auto-prune
```

Recheck the status again

```bash
argocd app get argo-$LAB_USER --refresh
```

Now the ImageStream was successfully deleted by Argo CD.

```
GROUP               KIND         NAMESPACE    NAME           STATUS     HEALTH   HOOK  MESSAGE
...
image.openshift.io  ImageStream  hannelore15  data-producer  Succeeded  Pruned         pruned
                    Service      hannelore15  data-producer  Synced     Healthy        service/data-producer unchanged
                    Service      hannelore15  data-consumer  Synced     Healthy        service/data-consumer unchanged
apps                Deployment   hannelore15  data-producer  Synced     Healthy        deployment.apps/data-producer unchanged
...

```


<!---

TODO: Berechtiungs Issues mit Argo CD ServiceAccount: dem SA system:serviceaccount:pitc-infra-argocd:argocd-application-controller fehlen die Berechtigungen auf <username>-pipeline zu schreiben. Der Rest für das additional Lab ist vorbereitet. 


## Task {{% param sectionnumber %}}.8: Additional Task

Setup a new Argo CD application which deployes the Tekton pipelines from the previous lab. You can do it on the web console or by cli.

<details><summary>solution with cli</summary>

```bash
argocd app create argo-$LAB_USER-pipelines --repo https://gitea.techlab.openshift.ch/$LAB_USER/gitops-resources.git --path $LAB_USER-pipelines --dest-server https://kubernetes.default.svc --dest-namespace $LAB_USER-pipelines
```

</details><br/>

--->
