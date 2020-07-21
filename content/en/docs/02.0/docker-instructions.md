---
title: "2.3 Docker Instructions"
linkTitle: "Docker Instructions"
weight: 230
sectionnumber: 2.3
description: >
  Docker instructions for building and publishing the Go application as container image.
---


## {{% param sectionnumber %}}.1 Docker instructions

Building, testing and publishing of the container image using [Docker](https://www.docker.com/). This includes the commands for [Lab: 2.1 Build a container image](build-container-image/).


### Image build

Docker build command:

```bash
docker build -t go-hello-world .
```


### Image test

Docker run command:

```bash
docker run -p 8080:8080 -ti go-hello-world
```

It can be tested with a browser (<http://localhost:8080/world>) or using curl:

```bash
curl localhost:8080/world
```


### Publish image to Docker Hub

```bash
docker login
docker tag go-hello-world:latest appuio/go-hello-world:latest
docker push appuio/go-hello-world:latest
```
