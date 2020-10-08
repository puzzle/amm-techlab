---
title: "About"
linkTitle: About
menu:
  main:
    weight: 3
---

{{% blocks/cover title="About" height="auto" %}}
Im Application "Migration and Modernization Techlab" lernen die Teilnehmenden anhand Präsentationen und Hands-on Labs, wie Applikationen in ihrer Systemlandschaft auf die neue Container Plattform gebracht werden können und welche architektonischen Grundprinzipien beachtet werden müssen, damit die Flexiblität und das Featureset der Container Plattform wirklich ausgereizt werden können. Die Teilnehmenden lernen moderne Konzepte kennen, wie Cloud Native Applikationen entwickelt und betrieben werden können.
{{% /blocks/cover %}}

{{% blocks/section type="section" color="white" %}}


### Lernziele

* Kennen die grundlegenden Kriterien, die zu beachten sind um eine Applikation auf eine Container Plattform zu migrieren und zu deployen.
* Lernen erweiterte Kubernetes resp. OpenShift Konzepte, welche zum Betrieb von Applikationen auf OpenShift nötig sind, kennen
* Architektonische Bestpractices für containerisierte Applikationen


### Inhalte

Gemeinsam mit dem Teacher wird, anhand einer Mischung aus Präsentation und Hands-on Labs, folgender Stoff behandelt.


#### Präsentation

* Einführung ins Thema Application Migration and Modernization
* Recap Container Technologie und OpenShift
* 12 Factor Apps und Bestpractices für moderne Applikationen
* Was muss besonders beachtet werden, wenn man Workload auf eine Container Plattform migriert.
* Build und Deplyoments auf OpenShift
* Continuous Integration und Delivery auf OpenShift


#### Labs

* Containerisierung einer Applikation Best Practices
* Builden und deployen von Applikation OpenShift
* Deployment einer Microservices Applikation Schritt für Schritt
  * Quarkus Microservices die mittels Rest resp. Kafka Topics kommunizieren
  * Kafka Server
* Automatisierung mit CI/CD Pipelines
  * CI/CD anhand von verschiedenen Beispielen und Best Practices
  * Tekton Pipelines
  * GitOps mit ArgoCD
* Observability
  * Monitoring und Application Metrics mit Prometheus.
  * Tracing.
* Weitere Themen
  * Requests and Limits
  * Jobs und Cronjobs
  * Autoscaling
  * Debugging
  * Operators
  * OpenShift odo


### Zielpublikum

Das Techlab richtet sich an OpenShift und Kubernetes Engineers mit Entwickler Fokus. Grundlegende Kenntnisse im Bereich Container Plattform, Cloud sollten vorhanden sein. Dieses Techlab baut auf dem [APPUiO Techlab](https://appuio.ch/techlabs.html) auf.


### Voraussetzungen

Alle Teilnehmenden benötigen für die Schulung einen Laptop (Dual-Core Prozessor, mind. 2GB RAM) mit Internetzugriff une einem Vorinstallierten WebBrowser. Die komplette Entwicklungsumgebung für das Lab wird webbasiert zur Verfügung gestellt. Für einzelne optionale Labs müssen gewissen Komponenten(argocd Client) local installiert werden.


### Sprache

Das Techlab findet in Deutsch oder Englisch statt, die Unterlagen stehen auf Englisch zur Verfügung


### Links

* [Anmeldung für das AMM Lab](https://appuio.ch/ammtechlab.html)
* [Blogpost Applikationen modernisieren und migrieren](https://www.puzzle.ch/de/blog/articles/2020/06/24/applikationen-modernisieren-und-migrieren)
* [Flyer zum AMM Angebot von Puzzle](https://www.puzzle.ch/wp-content/uploads/2020/06/2020_AMM_Flyer_A4_digital.pdf)


{{% /blocks/section %}}
