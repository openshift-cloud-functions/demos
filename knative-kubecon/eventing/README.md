# The EventSource Sample

In this folder there are a handful of YAML files, that needed in the `myproject` namespace of Openshift to run the demo.

## The ServiceAccount

The demo is run by the `default` Service account, but it needs the `event-watcher` role, run:

```
oc apply -f 000-rolebinding.yaml -n myproject
```

## The Channel

By default Eventing comes with the `in-memory-channel` _ClusterChannelProvisioner_. Next we create a _Channel_ for using the (default) ClusterChannelProvisioner:

```
oc apply -f 010-channel.yaml -n myproject
```

## The Kubernetes EventSource
The `knative-eventing` project comes with a set of EventSources. Next we are going to create a `KubernetesEventSource` for our namespace, which is sending Kubernetes platform events to the above _Channel_:

```
oc apply -f 020-k8s-event-source.yaml -n myproject
```

## The subscription
To glue it all together, we create a _Subscription_, that links a `ksvc` to a _Channel_ for receiving events. For that we leverage the `ksvc` that's used in the build/serving samples:

```
oc apply -f 030-subscription.yaml -n myproject
```
> NOTE: the `helloworld-openshift` name is referencing the previous used `ksvc` build!
