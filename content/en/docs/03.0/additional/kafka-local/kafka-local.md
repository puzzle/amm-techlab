---
title: "3.3.3 Kafka local"
linkTitle: "3.3.3 Kafka local"
weight: 333
sectionnumber: 3.3.3
description: >
  Run the event driven application with Apache Kafka local.
---

> Your WEB-IDE does not contain the needed tools for this lab. When you like to do it, you have to install the tools (Docker, docker-compose) on your computer.


## Task {{% param sectionnumber %}}.1: Run an event driven application on your computer

Let's get our kafka instance, producer and consumers up and running on your local machine.

> This is the correspondent lab to [Event driven architecture with Apache Kafka](../../../kafka/kafka/) where you run the application on OpenShift.

With the following docker-compose file you can start your own local kafka cluster.

```Dockerfile
version: '2'

services:

  zookeeper:
    image: strimzi/kafka:0.11.3-kafka-2.1.0
    command: [
      "sh", "-c",
      "bin/zookeeper-server-start.sh config/zookeeper.properties"
    ]
    ports:
      - "2181:2181"
    environment:
      LOG_DIR: /tmp/logs

  kafka:
    image: strimzi/kafka:0.11.3-kafka-2.1.0
    container_name: amm-kafka-cluster
    command: [
      "sh", "-c",
      "bin/kafka-server-start.sh config/server.properties --override listeners=$${KAFKA_LISTENERS} --override advertised.listeners=$${KAFKA_ADVERTISED_LISTENERS} --override zookeeper.connect=$${KAFKA_ZOOKEEPER_CONNECT}"
    ]
    depends_on:
      - zookeeper
    ports:
      - "9092:9092"
    environment:
      LOG_DIR: "/tmp/logs"
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9092
      KAFKA_LISTENERS: PLAINTEXT://0.0.0.0:9092
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
```

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/content/en/docs/03.0/additional/kafka-local/docker-compose.yml)

First we need to have the docker-compose file on your machine. Get it like this:

```s
curl https://raw.githubusercontent.com/puzzle/amm-techlab/master/content/en/docs/03.0/3.2/docker-compose.yml -sO docker-compose.yml
```

Start this kafka cluster with:

```s
docker-compose -f docker-compose.yml up
```

We can now start the data-producer microservice which will produce data and send it to a topic called 'manual'.
Run this command in a new terminal:

```s
docker run --rm --network host -e QUARKUS_PROFILE=dev -p 8080:8080 g1raffi/quarkus-techlab-data-producer:kafka
```

As soon as you start your microservice you will see that he will start to produce data to the kafka cluster. Let's verify this and consume our kafka topic manually.

The kafka cluster comes with some handy binaries that will allow you to do certain operations directly on the cluster. You can produce messages with the `kafka-console-producer` binary and consume records with the `kafka-console-consumer` binary.

We log into our kafka cluster with the docker interactive shell. Run this command in a new terminal:

```s
docker exec -it amm-kafka-cluster /bin/bash
```

When logged into your docker container you can start to consume data:

```s
[kafka@b6061841d63c kafka]$ ./bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic manual --from-beginning
```

Stop this consumer inside the container by pressing `Ctrl+C` and `Ctrl+D` to leave the container.

Additional we can start the consumer microservice as well which will start to consume the data produced by our data-producer microservice.

```s
docker run --rm --network host -e QUARKUS_PROFILE=dev -p 8080:8080 g1raffi/quarkus-techlab-data-consumer:kafka
```

You will see the console logs with the data consumed from the kafka topic. It works!
Stop the consumer with `Ctrl+C`.


### Lab cleanup

We have to stop the producer and the kafka cluster.

Find the terminal where you started the producer and press `Ctrl+C`.

Do the same for the terminal where you started kafka with docker-compose. Additional you can remove the stopped container with:

```s
docker-compose -f docker-compose.yml rm
```
