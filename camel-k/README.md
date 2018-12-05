# Camel K on Knative Eventing Demo

This is a demo showing how to run a [Camel K](https://github.com/apache/camel-k) integration on top of Knative Eventing in order to forward events from a Knative channel to a Slack room.

A recording showing the demo in action is available at [https://youtu.be/E3Pvd8oxpik](https://youtu.be/E3Pvd8oxpik).

## Environment setup

We assume that Knative Eventing **v0.2** is installed and ready to be used.

Camel K should be installed before running the integration. To install it (with cluster-admin rights):

```
oc create -f 000-camel-k-crd.yaml
```

Then switch to the namespace where you want to run the integration and install the operator:

```
oc project myproject
oc create -f 010-camel-k-operator.yaml
```

Now, check if the `in-memory-channel` cluster channel provisioner is installed:

```
oc get clusterchannelprovisioners.eventing.knative.dev
```

In case it's not present, follow the instructions in [the knative eventing repository](https://github.com/knative/eventing/tree/v0.2.0/config/provisioners/in-memory-channel) to
install the **in-memory** channel provisioner.

In order to use images from the internal registry, you should add it to the list of
registries in the ConfigMap `config-controller` of the `knative-serving` project.

To obtain the ip-address/port combination of the internal registry (that is usually something like `172.30.1.1:5000` on Minishift):

```
oc get imagestream | grep camel-k | tr "/" " " | awk '{print $2}' | head -1
```

Then edit the configmap to add it to the `.data.registriesSkippingTagResolving` property:

```
oc edit cm config-controller -n knative-serving
```

## Demo

Create a Knative channel named `slack`, using the in-memory provisioner:

```
oc create -f 020-channel.yaml
```

Check if the in-memory-channel is already installed

Using the instruction in the Knative **eventing-sources** repository, create a *Heartbeat* source that pushes hearts (`<3`) to the Knative channel named `slack`.
You can find a sample of heartbeat source [here](https://github.com/knative/eventing-sources/blob/v0.2.0/samples/sources_v1alpha1_containersources.yaml).
You need to set the following as sink:

```
# ...
  sink:
    apiVersion: eventing.knative.dev/v1alpha1
    kind: Channel
    name: slack
```

Now the source should be running and sending events to the `slack` Knative channel.

In order to forward events to a Slack room, you need to register an app in Slack:

- Go to [https://api.slack.com](https://api.slack.com) and register a new App
- From the "Features" menu, go to "Incoming Webhooks" and activate the feature
- Add a new incoming webhook by specifying the Slack room (channel) where you want to send messages to
- Copy the webhook URL and paste it in the `040-slack-integration.yaml` file, replacing the `<<put-here-the-webhook-url>>` placeholder

You can inspect the `040-slack-integration.yaml` file to notices how it's made. It contains a [snippet of Camel DSL](https://github.com/apache/camel/blob/master/docs/user-manual/en/java-dsl.adoc).

Now you can create the Camel K integration:

```
oc create -f 040-slack-integration.yaml
```

You should see a new `Integration` resource created, that in turn creates a child Knative service named `slack-integration`:

```
oc get services.serving.knative.dev
```

If no `slack-integration` service is present, you should wait for the operator to generate it (usually it takes ~15 seconds the first time).


The integration is going to contact `slack.com`, so you should enable it in the Istio rules.

```
oc create -f 050-istio.yaml
```

The last thing to do is to subscribe the Camel K service to the `slack` channel. This can be done with a standard Knative Eventing Subscription:

```
oc create -f 060-subscription.yaml
```

You should now see that the Slack room you've chosen is being filled with hearts (`<3`).
