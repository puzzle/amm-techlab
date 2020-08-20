---
title: "3.4 Best practices"
linkTitle: "Best practices"
weight: 34
sectionnumber: 3.4
description: >
  Best practices for creating OpenShift containers.
---
## TODO
 - Techlab
 - Root user hinzufpgen
 - FS Permission
- MultuiStage builds möglich? 


## Best practices for container in general

[Best practices for writing Dockerfiles](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)


### Instructions order


Bad:

```Dockerfile
FROM ubuntu
WORKDIR /home/me
COPY . src/
RUN apt get update && apt get install git openssh-client curl build-essential
```

In this case every time your source code changed and you build the Image, all the linux packages are installed again.

Good:

```Dockerfile
FROM ubuntu
WORKDIR /home/me
RUN apt get update && apt get install git openssh-client curl build-essential
COPY . src/

```

If you switch the RUN and COPY instructions, you only download the packages once. The layer is cached and will be reused for every further build.

### Use multistage build

To reduce the size of your Image, you can use [Multi-Stage Builds](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#use-multi-stage-builds). For example a multi stage build for a Go application look like follow:


```
{{< highlight dockerfile "hl_lines=1 5 6" >}}
FROM golang:1.14-alpine as builder
COPY main.go /opt/app-root/src
RUN env CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -o go-hello-world-app .

FROM scratch
COPY --from=builder /opt/app-root/src/go-hello-world-app /home/golang/
EXPOSE 8080
CMD /home/golang/go-hello-world-app

{{< / highlight >}}
```

In this example you can see a two layer build. The first layer (called builder) uses a alpine base Image with the Golang tools / libs. It is responsible for building the golang application. The second layer is based on the Docker Scratch Image. Scratch image is used for super minimal Images that contain only a single binary.
At line 6 the compiled binary from the build stage is copied into the second stage. This ensures that we only copy the artifacts we need into the final Image.


## Best practices for creating OpenShift containers

[OpenShift Container Platform-specific guidelines](https://docs.openshift.com/container-platform/4.5/openshift_images/create-images.html#images-create-guide-openshift_create-images)


### Root Users

Container Images which running under root user, are not permitted in OpenShift clusters.


### Random User IDs

Unlike Kubernetes, OpenShift uses arbitrary User IDs.


``` DOCKERFILE
RUN chgrp -R 0 /some/directory && \
    chmod -R g=u /some/directory
```



### File permissions

//TODO


### Logging

Always log to standard out. This makes it easier to collect the logs from the container and send it to an centralized logging service.


### Health checks (Readiness and liveness probe)
