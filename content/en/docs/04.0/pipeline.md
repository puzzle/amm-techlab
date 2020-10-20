---
title: "4.1 Tekton Pipelines"
linkTitle: "4.1 Tekton Pipelines"
weight: 410
sectionnumber: 4.1
description: >
  Build and deployment automation with Tekton on OpenShift.
---

It is time to automate the deployment of our Quarkus application to OpenShift by using OpenShift Pipelines. OpenShift Pipelines are based on [Tekton](https://tekton.dev/). In this example we will use the namespace to follow along the previous chapters. If you don't have your Kafka cluster, data-producer and data-consumer up and running please repeat the previous chapter to be ready to continue! We will create another microservice which consumes the same stream of data and transform the data to calculate a simple average count.


## Task {{% param sectionnumber %}}.1: Basic Concepts

Tekton makes use of several Kubernetes [custom resources (CRD)](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/).

These CRDs are:

* *[Task](https://github.com/tektoncd/pipeline/blob/master/docs/tasks.md)*: A collection of steps that perform a specific task.
* *[Pipeline](https://github.com/tektoncd/pipeline/blob/master/docs/pipelines.md)*: A series of tasks, combined to work together in a defined (structured) way
* *[PipelineResource](https://github.com/tektoncd/pipeline/blob/master/docs/resources.md)*: Inputs (e.g. git repository) and outputs (e.g. image registry) to and out of a pipeline or task
* *[TaskRun](https://github.com/tektoncd/pipeline/blob/master/docs/taskruns.md)*: The execution and result of running an instance of a task
* *[PipelineRun](https://github.com/tektoncd/pipeline/blob/master/docs/pipelineruns.md)*: The actual execution of a whole Pipeline, containing the results of the pipeline (success, failed...)

Pipelines and tasks should be generic and must never define possible variables - such as 'input git repository' - directly in their definition. Therefore, the concept of PipelineResources has been created. It defines and selects the parameters, that are being used during a PipelineRun.

![Static Pipeline Definition](../pipeline-static-definition.png)
*Static definition of a Pipeline*

For each task, a pod will be allocated and for each step inside this task, a container will be used.

![Pipeline Runtime View](../pipeline-runtime-view.png)
*Runtime view of a Pipeline showing mapping to pods and containers*

Ensure that the `LAB_USER` environment variable is still present.

```bash
echo $LAB_USER
```

If the result is empty, set the `LAB_USER` environment variable.

<details><summary>command hint</summary>

```bash
export LAB_USER=<username>
```

</details><br/>


Change to your main Project.

<details><summary>command hint</summary>

```bash
oc project $LAB_USER
```

</details><br/>

The OpenShift Pipeline operator automatically creates a pipeline ServiceAccount with all required permissions to build and push an image. This service account is used by PipelineRuns. List the service accounts of your project.

<details><summary>command hint</summary>

```bash
oc get ServiceAccount
```

Or use the abbreviation:

```bash
oc get sa
```

</details><br/>

Output listing the pipeline service account:

```
NAME       SECRETS   AGE
builder    2         11s
default    2         11s
deployer   2         11s
pipeline   2         11s
...
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

A Task is the smallest block of a Pipeline, which by itself can contain one or more steps. These steps are executed to process a specific element. For each task, a pod is allocated and each step is running in a container inside this pod. Tasks are reusable by other Pipelines. _Input_ and _Output_ specifications can be used to interact with other tasks.

{{% alert title="Note" color="primary" %}}
You can find more examples of reusable tasks in the [Tekton Catalog](https://github.com/tektoncd/catalog) and [OpenShift Catalog](https://github.com/openshift/pipelines-catalog) repositories.
{{% /alert %}}

Let's examine two tasks that do a deployment. Create the local file `<workspace>/deploy-tasks.yaml` with the following content:

```yaml
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: apply-manifests
spec:
  resources:
    inputs:
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

Let's create the tasks.

<details><summary>command hint</summary>

```bash
oc apply -f deploy-tasks.yaml
```

</details><br/>

Verify that the two tasks have been created using the Tekton CLI:

```bash
tkn task ls
```

```
NAME              DESCRIPTION   AGE
apply-manifests                 19 seconds ago
```


## Task {{% param sectionnumber %}}.4: Create a Pipeline

A pipeline is a set of tasks, which should be executed in a defined way to achieve a specific goal.

The example Pipeline below uses two resources:

* git-repo: defines the Git-Source
* image: Defines the target at a repository

It first uses the Task *buildah*, which is a default task the OpenShift operator created automatically. This task will build the image. The resulted image is pushed to an image registry, defined in the *output* parameter. After that, the created tasks *apply-manifest* is executed. The execution order of these tasks is defined with the *runAfter* Parameter in the YAML definition.

{{% alert title="Note" color="primary" %}}
The Pipeline should be reusable across multiple projects or environments, that's why the resources (git-repo and image) are not defined here. When a Pipeline is executed, these resources will get defined.
{{% /alert %}}

Create the following pipeline `<workspace>/deploy-pipeline.yaml`:

```yaml
apiVersion: tekton.dev/v1beta1
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
  - name: apply-manifests
    taskRef:
      name: apply-manifests
    resources:
      inputs:
      - name: source
        resource: git-repo
    runAfter:
    - build-image
```

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/04.0/4.1/deploy-pipeline.yaml)

Create the Pipeline.

<details><summary>command hint</summary>

```bash
oc apply -f deploy-pipeline.yaml
```

</details><br/>

which will result in: `pipeline.tekton.dev/build-and-deploy created`

Verify that the Pipeline has been created using the Tekton CLI:

```bash
tkn pipeline ls
```

```
NAME               AGE              LAST RUN   STARTED   DURATION   STATUS
build-and-deploy   19 seconds ago   ---        ---       ---        ---
```


## Task {{% param sectionnumber %}}.5: Trigger Pipeline

After the Pipeline has been created, it can be triggered to execute the tasks.


### Create PipelineResources

Since the Pipeline is generic, we first need to define 2 *PipelineResources* to execute a Pipeline.
We are going to automate the deployment of our sample application we used in previous examples. There will be one microservices deployed, the data-transformer.

Quick overview:

* transformer-repo: will be used as _git_repo_ in the Pipeline for the data consumer
* transformer-image: will be used as _image_ in the Pipeline for the data consumer

{{% alert title="Note" color="primary" %}}
We use a template to adapt the image registry URL to match to your project.
{{% /alert %}}

Create the following openshift template `<workspace>/pipeline-resources-template.yaml`:

```yaml
apiVersion: template.openshift.io/v1
kind: Template
metadata:
  name: pipeline-resources-template
  annotations:
    description: 'Template to create project specific Pipeline resources.'
objects:
- apiVersion: tekton.dev/v1alpha1
  kind: PipelineResource
  metadata:
    name: transformer-repo
  spec:
    type: git
    params:
    - name: url
      value: https://github.com/puzzle/quarkus-techlab-data-transformer.git
    - name: revision
      value: master
- apiVersion: tekton.dev/v1alpha1
  kind: PipelineResource
  metadata:
    name: transformer-image
  spec:
    type: image
    params:
    - name: url
      value: image-registry.openshift-image-registry.svc:5000/${PROJECT_NAME}/data-transformer:latest
parameters:
- description: OpenShift Project Name
  name: PROJECT_NAME
```

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/04.0/4.1/pipeline-resources-template.yaml)

Create the Pipeline resources by processing the template and creating the generated resources:

```bash
oc process -f pipeline-resources-template.yaml \
  --param=PROJECT_NAME=$(oc project -q) \
| oc apply -f-
```

will result in:

```
pipelineresource.tekton.dev/transformer-repo created
pipelineresource.tekton.dev/transformer-image created
```

The resources can be listed with:

```bash
tkn resource ls
```

```
NAME             TYPE    DETAILS
transformer-repo    git     url: https://github.com/puzzle/quarkus-techlab-data-transformer.git
transformer-image   image   url: image-registry.openshift-image-registry.svc:5000/<userXY>/data-transformer:latest
```


### Execute Pipelines using tkn

Start the Pipeline for the data-transformer:

```bash
tkn pipeline start build-and-deploy \
-r git-repo=transformer-repo \
-r image=transformer-image \
-p deployment-name=data-transformer \
-s pipeline
```

This will create and execute a PipelineRun. Use the command `tkn pipelinerun logs build-and-deploy-run-<pod> -f -n <userXY>-pipelines` to display the logs

The PipelineRuns can be listed with:

```bash
tkn pipelinerun ls
```

```
NAME                         STARTED          DURATION    STATUS
build-and-deploy-run-5r2ln   8 minutes ago    1 minute    Succeeded
```

Moreover, the logs can be viewed with the following command and selecting the appropriate Pipeline and PipelineRun:

```bash
tkn pipeline logs
```


## Task {{% param sectionnumber %}}.6: OpenShift WebUI

Go tho the developer view of the WebUI of OpenShift and select your pipeline project.

Do you remember that you did not create any Deployment for your application? That has been done by your Tekton pipeline.

With the OpenShift Pipeline operator, a new menu item is introduced to the WebUI of OpenShift named Pipelines. All Tekton CLI commands, which are used above, could be replaced with the web interface. The big advantage is the graphical presentation of Pipelines and their lifetime.


### Checking your application

Check the logs of your data-transformer microservice. You will see that he will start to log average data consumed from the data stream.


## High quality and secure Pipeline

This was just an example for a pipeline, that builds and deploys a container image to OpenShift. There are lots of security features missing.

Check out the Puzzle [delivery pipeline concept](https://github.com/puzzle/delivery-pipeline-concept) for further information.


## Links and Sources

* [Tekton](https://tekton.dev/)
* [Understanding OpenShift Pipelines](https://docs.openshift.com/container-platform/latest/pipelines/understanding-openshift-pipelines.html)
* [Creating CI/CD solutions for applications using OpenShift Pipelines](https://docs.openshift.com/container-platform/latest/pipelines/creating-applications-with-cicd-pipelines.html)
* [Pipeline-Tutorial](https://github.com/openshift/pipelines-tutorial/)
* [Interactive OpenShift Pipelines tutorial](https://learn.openshift.com/middleware/pipelines/)on [learn.openshift.com](https://learn.openshift.com/)
