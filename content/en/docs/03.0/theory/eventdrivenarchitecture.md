---
title: "3.1 Event driven architecture theory"
linkTitle: "3.1 Event driven architecture theory"
weight: 31
sectionnumber: 3.1
description: >
   Theory of event driven architecture.
---


## {{% param sectionnumber %}}.1: Event driven architecture

When designing applications or software systems we usually tend to follow a very imperative way of building our components. Especially in monolithic applications, the communication between two components will often come from function or method calls from one component to another. Even when we follow a microservice architecture the most intuitive way for most people would be to simply replace these calls with REST calls. In theory, this is a valid approach and will often be the first step when migrating a monolith towards a microservice approach. The downside, however, will be the same. Whenever two components talk directly to each other they rely on an often synchronous direct communication channel. What happens if the other component is not available?

Let's take a look at an example to make our point. Imagine we have an application or software systems where you can order shoes. An example workflow would be a user selecting their desired shoes, starting an order, and finally paying it. Eventually, this will trigger a shipment.

* shop component: Which handles all the products available.
* order component: Handles products which were ordered.
* payment component: Which handles all payment related issues.

If we would implement this with synchronous communication the system would look something like this:

```
+------------+                     +------------+                     +--------------+
| shop       |        create order | order      |     process payment |   payment    |
| component  +-------------------->+ component  +-------------------->+   component  |
+------------+                     +------------+                     +--------------+
```

If the order component breaks down or will not accept any communication, the shop component must handle the entire fault tolerance and the system's reliability will depend on its error handling.

We can take a step back now and take a look at this workflow from another perspective. On a meta level all the workflows in this application do get triggered by events. We can think of the order or the payment request as events. The order component should not really care from whom the order comes nor should the shop component care from where this event was triggered. The entire workflow abandons the pattern where we rely on any calls from one component to another. We just emit events whenever another workflow should be triggered. The components listen to a stream of such events and will start their connected workflow.

For handling those streams of events, we need a message broker. Whenever an event gets triggered by a component, or the component sends a message to the message broker. The broker then distributes these events between a set of subscriber components.

The architecture might look something like this:

```
              +------------------+                +-----------------+
      +------->     orders       |---+        +---> payment request +-----+
      |       +------------------+   |        |   +-----------------+     |
      |                              |        |                           |
+-------------+                    +-v----------+                     +---v----------+
| shop        |                    | order      |                     |   payment    |
| component   |                    | component  |                     |   component  |
+-------------+                    +------------+                     +--------------+
```

In this example, the shop component emits an event to a data stream called orders. The order component subscribes to the orders data stream and gets notified whenever an event is submitted and can be handled. Finally, an event is being emitted to the payment request, which will then get processed by the subscribing payment component.

This pattern is called event-driven architecture. Event-driven architecture loosens the coupling between components drastically. Even if a component fails or is unavailable, the events will stay persisted in the message broker and can be processed whenever the system is up and running again.

Here are some additional practices and design patterns for event-driven architectures:


### {{% param sectionnumber %}}.1.1: Event notification

In this approach, microservices emit events through channels to trigger behavior or notify other components about the change of a state in the application. Notification events do not carry too much data and are very lightweight. This results in very effective and resource-friendly communication between the microservices.


### {{% param sectionnumber %}}.1.2: Event-carried state transfer

Instead of only notifying about events, this approach sends a payload as a message to another component, containing every required information to perform actions triggered by this event. That model comes very close to the typical RESTful approach and can be implemented very similarly. Depending on the amount of data in the payload, the network traffic might suffer under the amount of data transferred.


### {{% param sectionnumber %}}.1.3: Event-sourcing

The goal of event-sourcing is to represent every change in a system's state as an emitted event in chronological order. The event stream becomes the principal source of truth about the application's state. Changes in state, as sequences of events, are persisted in the event stream and can be 'replayed'.


### {{% param sectionnumber %}}.1.4: Additional Links

* [What do you mean by “Event-Driven”? (Martin Fowler)](https://martinfowler.com/articles/201701-event-driven.html)
* [Event-Driven Architecture (Mark Richards)](https://www.oreilly.com/library/view/software-architecture-patterns/9781491971437/ch02.html)
