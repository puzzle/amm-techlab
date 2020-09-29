---
title: "9.2.3 Docker Build"
linkTitle: "Docker Build"
weight: 923
sectionnumber: 9.2.3
description: >
  Building images using Docker Build.
---


## {{% param sectionnumber %}}.1 Lab


## TODO Lab

* [ ] Build Config yaml erstellen und applyen
  * Beschreiben, dass privilegierte Rechte notwendig sind um Docker Builds auszuführen. (zuerst überprüfen ob notwendig)
  * Hinweis: From Teil vom Docker File wird in BC überschrieben
* [ ] Build anschauen
* [ ] DeploymentConfig, Service, Route auch noch via oc apply erstellen und dann entsprechend die App aufrufen


The Docker build strategy was already used in Lab 2. We don't repeat it here. The Docker Strategy expects a `Dockerfile` at the root of the Project. For every Build it invokes the Docker build command and produces a runnable Image.
