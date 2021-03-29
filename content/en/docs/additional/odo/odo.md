---
title: "OpenShift Do (odo)"
linkTitle: "OpenShift Do odo"
weight: 91
sectionnumber: 9.1
description: >
  Developing applications on OpenShift with the new OpenShift developer cli.
---

## {{% param sectionnumber %}}.1 odo

OpenShift Do ([odo](https://github.com/openshift/odo)) is a fast and easy-to-use CLI tool for creating applications on OpenShift. Main purpose is to support application development with OpenShift. It is similar to [Yeoman](https://yeoman.io/) and has been introduced with OpenShift v4.

Let's see, what components/languages are supported.

```bash
odo catalog list components
```

```
Odo OpenShift Components:
NAME              PROJECT       TAGS                   SUPPORTED
java              openshift     11,8,latest            YES
nodejs            openshift     10,12,latest           YES
dotnet            openshift     2.1,3.0,3.1,latest     NO
golang            openshift     1.11.5,latest          NO
httpd             openshift     2.4,latest             NO
modern-webapp     openshift     10.x,latest            NO
nginx             openshift     1.10,1.14,latest       NO
perl              openshift     5.26,latest            NO
php               openshift     7.2,7.3,latest         NO
python            openshift     2.7,3.6,latest         NO
ruby              openshift     2.4,2.5,latest         NO
```


## {{% param sectionnumber %}}.2 Initialize project


We first check that the project is ready for the lab.

Ensure that the `LAB_USER` environment variable is set.

```bash
echo $LAB_USER
```

If the result is empty, set the `LAB_USER` environment variable.

<details><summary>command hint</summary>

```bash
export LAB_USER=<username>
```

</details><br/>

Prepare a project and configure the development of a Go application.

Create project:

```bash
oc new-project $LAB_USER-odo
```

Use a new folder to store the odo configuration and the application files. Create the folder with name `odo-application` and go into it:

```bash
mkdir odo-application
cd odo-application
```

Prepare configuration locally:

```bash
odo create --s2i golang --port 8080
```

Display configuration:

```bash
odo config view
```

```
COMPONENT SETTINGS
------------------------------------------------
PARAMETER         CURRENT_VALUE
Type              golang
Application       app
Project           odo-<username>
SourceType        local
Ref
SourceLocation    ./
Ports             8080
Name              golang-odo-ontc
MinMemory
MaxMemory
DebugPort
Ignore
MinCPU
MaxCPU
```


## {{% param sectionnumber %}}.3 Create Application

Create the file `main.go` with the content of the go-hello-world application ([source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/additional/odo/main.go)).

```bash
wget 'https://raw.githubusercontent.com/puzzle/amm-techlab/master/manifests/additional/odo/main.go' main.go
```

This all happened locally. Use `odo push` to create the component in OpenShift.

```bash
odo push
```

```
Validation
 ✓  Checking component [226ms]

Configuration changes
 ✓  Initializing component
 ✓  Creating component [664ms]

Applying URL changes
 ✓  URLs are synced with the cluster, no changes are required.

Pushing to component golang-odo-applicat-asqd of type local
 ✓  Checking files for pushing [320679ns]
 ✓  Waiting for component to start [1m]
 ✓  Syncing files to the component [706ms]
 ✓  Building component [2s]
 ✓  Changes successfully pushed to component
```

All needed resources have been created. The command exited after a successful start of the pod.


## {{% param sectionnumber %}}.4 Create Route

To access the application from outside OpenShift a route is needed. A secure route can be created with odo:

```bash
odo url create go-app --secure
```

That changed the configuration locally, use `odo push` to create the route:

```bash
odo push
```

```
Validation
 ✓  Checking component [247ms]

Configuration changes
 ✓  Retrieving component data [318ms]
 ✓  Applying configuration [336ms]

Applying URL changes
 ✓  URL go-app: https://go-app-app-odo-<username>.{{% param techlabClusterDomainName %}} created

Pushing to component golang-odo-applicat-asqd of type local
 ✓  Checking file changes for pushing [958674ns]
 ✓  No file changes detected, skipping build. Use the '-f' flag to force the build.
```

Display URL configuration and state:

```bash
odo url list
```


## {{% param sectionnumber %}}.5 Access and Test Application

Browse to the URL from the previous chapter and add the path `/world`. This can also be done with curl:

```bash
curl https://go-app-app-odo-$LAB_USER.{{% param techlabClusterDomainName %}}/world
```

```
Hello, world!
```


## {{% param sectionnumber %}}.6 Change the Application

To develop applications, odo has a watch feature. It syncs changes automatically to OpenShift.

Start the watch feature:

```bash
odo watch &
```

{{% alert title="Note" color="primary" %}}
The & at the end runs the watch in the background.
{{% /alert %}}

Now we change the Go application to return `Howdy` instead of `Hello`. It must be done inside the copied `main.go` file. Sed will do the replacement for us:

```bash
sed -i "s/Hello,/Howdy,/" main.go
```

odo directly builds the application and deploys the changes to OpenShift.

```
File odo/main.go changed
Pushing files...
 ✓  Waiting for component to start [59ms]
 ✓  Syncing files to the component [437ms]
 ✓  Building component [3s]
```

Call the URL of the application again to test the changes.

```bash
curl https://go-app-app-odo-$LAB_USER.{{% param techlabClusterDomainName %}}/world
```

```
Howdy, world!
```

## {{% param sectionnumber %}}.7 Links

* [odo](https://github.com/openshift/odo)
* [odo installation](https://docs.openshift.com/container-platform/latest/cli_reference/developer_cli_odo/installing-odo.html)
* [interactive odo tutorial](https://developers.redhat.com/courses/openshift/odo-command-line)
