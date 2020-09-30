---
title: "4.1 Tekton Pipelines"
linkTitle: "4.1 Tekton Pipelines"
weight: 410
sectionnumber: 4.1
description: >
  Build and deployment automation with Tekton on OpenShift.
---

## TODO

* [ ] Testen und durchspielen
* [ ] ev. Tekton zusammen erarbeiten und auf git pushen
* [ ] Bspw. eine ENV anpassen und dann die Pipeline starten.
* [ ] Maria DB auch noch definieren als DeploymentConfig und Ressource im Git Repo erstellen (Analog APPUiO Techlab Lab 8) resp. via Pipeline Deployen
* [ ] App so umkonfigurieren, dass die sie neu die DB verwendet.
* [ ] Tekton lab, evtl. anhand von der App oben:
  * [x] Basis Red Hat nehmen
    * [ ] und vielleicht wenn die Zeit noch da ist auf unsere App umstellen
* [ ] ev. noch mit [WebHook](https://docs.openshift.com/container-platform/4.4/pipelines/creating-applications-with-cicd-pipelines.html#creating-webhooks_creating-applications-with-cicd-pipelines) erweitern
* [ ] ev. mit Task aus Catalog erweitern: <https://github.com/tektoncd/catalog> oder <https://github.com/openshift/pipelines-catalog>
* [ ] Security Aspekte einfliessen lassen. im Lab Text schreiben, Waf vorschalten, Owasp checks machen, Zap Proxy


We will deploy an example application to test OpenShift Pipelines. OpenShift Pipelines are based on [Tekton](https://tekton.dev/).


## Task {{% param sectionnumber %}}.1: Basic Concepts

Tekton makes use of several Kubernetes [custom resources (CRD)](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/).

These CRDs are:

* *[Task](https://github.com/tektoncd/pipeline/blob/master/docs/tasks.md)*: a collection of steps that perform a specific task.
* *[Pipeline](https://github.com/tektoncd/pipeline/blob/master/docs/pipelines.md)*: is a series of tasks, combined to work together in a defined (structured) way
* *[PipelineResource](https://github.com/tektoncd/pipeline/blob/master/docs/resources.md)*: inputs (e.g. git repository) and outputs (e.g. image registry) to and out of a pipeline or task
* *[TaskRun](https://github.com/tektoncd/pipeline/blob/master/docs/taskruns.md)*: the execution and result of running an instance of a task
* *[PipelineRun](https://github.com/tektoncd/pipeline/blob/master/docs/pipelineruns.md)*: is the actual execution of a whole Pipeline, containing the results of the pipeline (success, failed...)

Pipelines and tasks should be generic and must never define possible variables - such as 'input git repository' - directly in their definition. Therefore, the concept of PipelineResources has been created. It defines and selects the parameters, that are being used during a PipelineRun.

![Static Pipeline Definition](../pipeline-static-definition.png)
*Static definition of a Pipeline*

For each task, a pod will be allocated and for each step inside this task, a container will be used.

![Pipeline Runtime View](../pipeline-runtime-view.png)
*Runtime view of a Pipeline showing mapping to pods and containers*

We start by creating a new project:

```bash
oc new-project <user>-pipelines
```

The OpenShift Pipeline operator will automatically create a pipeline serviceaccount with all required permissions to build and push an image. This serviceaccount is used by PipelineRuns:

```bash
oc get sa
```

```
NAME       SECRETS   AGE
builder    2         11s
default    2         11s
deployer   2         11s
pipeline   2         11s
```


## Task {{% param sectionnumber %}}.2: Tekton CLI tkn

For additional features, we are going to add another CLI that eases access to the Tekton resources and gives you more direct access to the OpenShift Pipeline semantics:

Verify tkn version by running:

```bash
tkn version
```

```
Client version: 0.10.0
Pipeline version: unknown
Triggers version: unknown
```


## Task {{% param sectionnumber %}}.3: Create Pipeline tasks

A Task is the smallest block of a Pipeline which by itself can contain one or more steps. These steps are executed to process a specific element. For each task, a pod is allocated and each step is running in a container inside this pod. Tasks are reusable by other Pipelines. _Input_ and _Output_ specifications can be used to interact with other Tasks.

{{% alert title="Note" color="primary" %}}
You can find more examples of reusable tasks in the [Tekton Catalog](https://github.com/tektoncd/catalog) and [OpenShift Catalog](https://github.com/openshift/pipelines-catalog) repositories.
{{% /alert %}}

Let's examine two tasks that do a deployment. Create the local file `<workspace>/deploy-tasks.yaml` with the following content:

```yaml
# deploy-tasks.yaml
apiVersion: tekton.dev/v1alpha1
kind: Task
metadata:
  name: apply-manifests
spec:
  inputs:
    resources:
      - {type: git, name: source}
    params:
      - name: manifest_dir
        description: The directory in source that contains yaml manifests
        type: string
        default: "src/main/openshift/templates"
  steps:
    - name: apply
      image: appuio/oc:v4.3
      workingDir: /workspace/source
      command: ["/bin/bash", "-c"]
      args:
        - |-
          echo Applying manifests in $(inputs.params.manifest_dir) directory
          oc apply -f $(inputs.params.manifest_dir)
          echo -----------------------------------

```

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/04.0/4.1/deploy-tasks.yaml)

Let's create the tasks:

```bash
oc apply -f deploy-tasks.yaml
```

Verify that the two tasks have been created using the Tekton CLI:

```bash
tkn task ls
```

```
NAME                AGE
apply-manifests     7 minutes ago
```


## Task {{% param sectionnumber %}}.4: Create a Pipeline

A pipeline is a set of tasks, which should be executed in a defined way to achieve a specific goal.

The example Pipeline below uses two resources:

* git-repo: defines the Git-Source
* image: Defines the target at a repository

It first uses the Task *buildah*, which is a default task the OpenShift operator created automatically. This task will build the image. The resulted image is pushed to an image registry, defined in the *output* parameter. After that, the created tasks *apply-manifest* is executed. The execution order of these tasks is defined with the *runAfter* Parameter in the yaml definition.

{{% alert title="Note" color="primary" %}}
The Pipeline should be re-usable across multiple projects or environments, that's why the resources (git-repo and image) are not defined here. When a Pipeline is executed, these resources will get defined.
{{% /alert %}}

Create the following pipeline `<workspace>/deploy-pipeline.yaml`:

```yaml
# deploy-pipeline.yaml
apiVersion: tekton.dev/v1alpha1
kind: Pipeline
metadata:
  name: build-and-deploy
spec:
  resources:
  - name: git-repo
    type: git
  - name: image
    type: image
  params:
  - name: deployment-name
    type: string
    description: name of the deployment to be patched
  - name: docker-file
    description: Path to the Dockerfile
    default: src/main/docker/Dockerfile.multistage.jvm
  tasks:
  - name: apply-manifests
    taskRef:
      name: apply-manifests
    resources:
      inputs:
      - name: source
        resource: git-repo
  - name: build-image
    taskRef:
      name: buildah
      kind: ClusterTask
    resources:
      inputs:
      - name: source
        resource: git-repo
      outputs:
      - name: image
        resource: image
    params:
    - name: TLSVERIFY
      value: "false"
    - name: DOCKERFILE
      value: $(params.docker-file)
    runAfter:
    - apply-manifests
```

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/04.0/4.1/deploy-pipeline.yaml)

Create the Pipeline:

```bash
oc create -f deploy-pipeline.yaml
```

which will result in: `pipeline.tekton.dev/build-and-deploy created`

Verify that the Pipeline has been created using the Tekton CLI:

```bash
tkn pipeline ls
```

```
NAME               AGE              LAST RUN   STARTED   DURATION   STATUS
build-and-deploy   34 seconds ago   ---        ---       ---        ---
```


## Task {{% param sectionnumber %}}.5: Trigger Pipeline

After the Pipeline has been created, it can be triggered to execute the Tasks.


### Create PipelineResources

Since the Pipeline is generic, we first need to define 2 *PipelineResources*, to execute a Pipeline.
We are going to automate the deployment of our sample application we used in previous examples. There will be two microservices deployed, a data producer and a data consumer.

Quick overview:

* consumer-repo: will be used as _git_repo_ in the Pipeline for the data consumer
* consumer-image: will be used as _image_ in the Pipeline for the data consumer
* producer-repo: will be used as _git_repo_ in the Pipeline for the data producer
* producer-image: will be used as _image_ in the Pipeline for the data producer

{{% alert title="Note" color="primary" %}}
We use a template to adapt the image registry URL to match to your project.
{{% /alert %}}

Create the following openshift template `<workspace>/deploy-resources-template.yaml`:

```yaml
# pipeline-resources-template.yaml
apiVersion: v1
kind: Template
metadata:
  name: pipeline-resources-template
  annotations:
    description: 'Template to create project specific Pipeline resources.'
objects:
- apiVersion: tekton.dev/v1alpha1
  kind: PipelineResource
  metadata:
    name: consumer-repo
  spec:
    type: git
    params:
    - name: url
      value: https://github.com/puzzle/quarkus-techlab-data-consumer.git
    - name: revision
      value: tekton
- apiVersion: tekton.dev/v1alpha1
  kind: PipelineResource
  metadata:
    name: consumer-image
  spec:
    type: image
    params:
    - name: url
      value: image-registry.openshift-image-registry.svc:5000/${PROJECT_NAME}/data-consumer:latest
- apiVersion: tekton.dev/v1alpha1
  kind: PipelineResource
  metadata:
    name: producer-repo
  spec:
    type: git
    params:
    - name: url
      value: https://github.com/puzzle/quarkus-techlab-data-producer.git
    - name: revision
      value: tekton
- apiVersion: tekton.dev/v1alpha1
  kind: PipelineResource
  metadata:
    name: producer-image
  spec:
    type: image
    params:
    - name: url
      value: image-registry.openshift-image-registry.svc:5000/${PROJECT_NAME}/data-producer:latest
parameters:
- description: OpenShift Project Name
  name: PROJECT_NAME
  mandatory: true
```

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/04.0/4.1/pipeline-resources-template.yaml)

Create the Pipeline resources by processing the template and creating the generated resources:

```bash
oc process -f pipeline-resources-template.yaml \
  --param=PROJECT_NAME=$(oc project -q) \
| oc create -f-
```

will result in:

```bash
pipelineresource.tekton.dev/consumer-repo created
pipelineresource.tekton.dev/consumer-image created
pipelineresource.tekton.dev/producer-repo created
pipelineresource.tekton.dev/producer-image created
```

The resources can be listed with:

```bash
tkn resource ls
```

```
NAME             TYPE    DETAILS
consumer-repo    git     url: https://github.com/puzzle/quarkus-techlab-data-consumer.git
producer-repo    git     url: https://github.com/puzzle/quarkus-techlab-data-producer.git
consumer-image   image   url: image-registry.openshift-image-registry.svc:5000/<user>-pipelines/data-consumer:latest
producer-image   image   url: image-registry.openshift-image-registry.svc:5000/<user>-pipelines/data-producer:latest

```


### Execute Pipelines using tkn

Start the Pipeline for the data-consumer:

```bash
tkn pipeline start build-and-deploy \
-r git-repo=consumer-repo \
-r image=consumer-image \
-p deployment-name=data-consumer \
-s pipeline
```

This will create and execute a PipelineRun. Use the command `tkn pipelinerun logs build-and-deploy-run-<pod> -f -n <user>-pipelines` to display the logs

Now start the same Pipeline with the producer resources:

```bash
tkn pipeline start build-and-deploy \
-r git-repo=producer-repo \
-r image=producer-image \
-p deployment-name=data-producer \
-s pipeline
```

The PipelineRuns can be listed with:

```bash
tkn pipelinerun ls
```

```
NAME                         STARTED          DURATION    STATUS
build-and-deploy-run-5r2ln   8 minutes ago    1 minute    Succeeded
build-and-deploy-run-9w67k   10 minutes ago   1 minute    Succeeded
```

Moreover, the logs can be viewed with the following command and selecting the appropriate Pipeline and PipelineRun:

```bash
tkn pipeline logs
```


## Task {{% param sectionnumber %}}.6: OpenShift WebUI

With the OpenShift Pipeline operator, a new menu item is introduced to the WebUI of OpenShift. All Tekton CLI commands, which are used above, could be replaced with the web interface. The big advantage is the graphical presentation of Pipelines and their lifetime.


### Checking your application

Now our Pipeline is built and deployed the voting application. Now you can vote whether you prefer cats or dogs (Cats or course :) )

Get the route of your project and open the URL in the browser.


## High quality and secure Pipeline

This was just an example for a pipeline, that builds and deploys a container image to OpenShift. There are lots of security features missing.

checkout the Puzzle [delivery pipeline concept](https://github.com/puzzle/delivery-pipeline-concept) for further infos.


## Links and Sources

* [Tekton](https://tekton.dev/)
* [Understanding OpenShift Pipelines](https://docs.openshift.com/container-platform/latest/pipelines/understanding-openshift-pipelines.html)
* [Creating CI/CD solutions for applications using OpenShift Pipelines](https://docs.openshift.com/container-platform/latest/pipelines/creating-applications-with-cicd-pipelines.html)
* [Pipeline-Tutorial](https://github.com/openshift/pipelines-tutorial/)
* [Interactive OpenShift Pipelines tutorial](https://learn.openshift.com/middleware/pipelines/)on [learn.openshift.com](https://learn.openshift.com/)
