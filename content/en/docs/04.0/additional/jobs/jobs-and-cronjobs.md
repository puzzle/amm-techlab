---
title: "4.3.3 Jobs and Cronjobs"
linkTitle: "4.3.3 Jobs and Cronjobs"
weight: 433
sectionnumber: 4.3.3
description: >
  Working with Jobs and Cronjobs.
---

<!--

## TODO

* [ ] Testen und durchspielen, allenfalls auf maria
* [ ] eigenes Projekt nehme
* [ ] Lab / Project Setup analog anderer Labs
* [ ] Ressourcen Files nicht in WS Folder ablegen!

-->

Jobs are different from normal Deployments: Jobs execute a time-constrained operation and report the result as soon as they are finished; think of a batch job. To achieve this, a Job creates a Pod and runs a defined command. A Job isn't limited to create a single Pod, it can also create multiple Pods. When a Job is deleted, the Pods started (and stopped) by the Job are also deleted.

For example, a Job is used to ensure that a Pod is run until its completion. If a Pod fails, for example because of a Node error, the Job starts a new one. A Job can also be used to start multiple Pods in parallel.

More detailed information can be retrieved from [OpenShifts Jobs Documentation](https://docs.openshift.com/container-platform/4.5/nodes/jobs/nodes-nodes-jobs.html).


## Task {{% param sectionnumber %}}.1: Create a Job for a MySQL Dump

As an example we want to create a dump of a running Maria database, but without the need of interactively logging into the Pod.

Let's first create the Maria deployment.

```bash
oc new-app mariadb-ephemeral \
   -pMYSQL_USER=appuio \
   -pMYSQL_PASSWORD=appuio \
   -pMYSQL_DATABASE=appuio
```

Let's first look at the Job resource that we want to create.

{{< readfile file="/manifests/04.0/4.3.3/job_mysql-dump.yaml" code="true" lang="yaml" >}}

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/main/manifests/04.0/4.3.3/job_mysql-dump.yaml)

The parameter `.spec.template.spec.containers[0].image` shows that we use the same image as the running database. In contrast to the database Pod, we don't start a database afterwards, but run a `mysqldump` command, specified with `.spec.template.spec.containers[0].command`. To perform the dump, we use the environment variables of the database deployment to set the hostname, user and password parameters of the `mysqldump` command. The `MYSQL_PASSWORD` variable refers to the value of the secret, which is already used for the database Pod. Like this we ensure that the dump is performed with the same credentials.

Let's create our Job: Create a file `job_mysql-dump.yaml` with the content above:

```bash
oc create -f ./job_mysql-dump.yaml
```

Check if the Job was successful:

```bash
oc describe jobs/mysql-dump
```

The executed Pod can be shown as follows:

```bash
oc get pods
```

To show all Pods belonging to a Job in a human-readable format, the following command can be used:

```bash
oc get pods --selector=job-name=mysql-dump --output=go-template='{{range .items}}{{.metadata.name}}{{end}}'
```


## CronJobs

A Kubernetes CronJob is nothing else than a resource which creates a Job at a defined time, which in turn starts (as we saw in the previous section) a Pod to run a command. Typical use cases are cleanup Jobs, which tidy up old data for a running Pod, or a Job to regularly create and save a database dumps, batch jobs that create reports and so on.

Further information can be found at the [OpenShift CronJob Documentation](https://docs.openshift.com/container-platform/4.5/nodes/jobs/nodes-nodes-jobs.html#nodes-nodes-jobs-creating-cron_nodes-nodes-jobs).

{{< readfile file="/manifests/04.0/4.3.3/cronjob_mysql-dump.yaml" code="true" lang="yaml" >}}

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/main/manifests/04.0/4.3.3/cronjob_mysql-dump.yaml)

Let's now create a CronJob that executes our Backup every day at the same time. Create a file `cronjob_mysql-dump.yaml` with the content above:

```bash
oc create -f cronjob_mysql-dump.yaml
```

And use the following command to explore the new resource:

```bash
oc get cronjob mysql-backup -o yaml
```

{{% alert title="Note" color="primary" %}}
It's very important, that you monitor Backups and regularly check them with so called restore tests. In our example above we store the dump into the `tmp` directory. That's only for demonstration purposes. In a real life, production example you would attach a volume and store the dump on it or upload it to a S3 bucket.
{{% /alert %}}
