# Knative and OpenShift Demo for KubeCon

This is a Knative on OpenShift demo as given at KubeCon. It walks you through on what Knative has to
offer:

1. It builds an application through Knative's Build component (which makes use of the existing OpenShift
Build mechanic underneath).
2. The built image is then deployed as a Knative Service, which means it scales automatically, even down
to nothing as we'll see.
3. We wire an EventSource emitting Kubernetes events to our application through Knative's Eventing capabilities.

## 0. Setting up an OpenShift cluster

Before we get started, let's setup an environment. This setup guide assumes the usage of `minishift` and the
setup scripts are tailored to facilitate that. To setup a fresh minishift cluster with OLM, Istio and all parts
we need from Knative installed, run the following script:

```bash
$ git clone git@github.com:openshift-cloud-functions/knative-operators.git
$ ./knative-operators/etc/scripts/install.sh
```

> This script is destructive towards the 'knative' profile in minishift.

After this script exits without any errors, your cluster will be setup and ready to go. Next, let's make `oc`
(OpenShift's CLI) available in the current terminal:

```bash
$ eval $(minishift oc-env)
```

There we are, let's get crackin'.

## 1. The Build component

The Build component in Knative is not so much a utility to build images themselves. It rather provides primitives,
to be able to string together the tools you want to do your image build. In a sense, it's an abstraction layer above
all the tools out there to build an image. In our case, the most prominent example is OpenShift's own build capability,
so this will show you, how we can implement a Knative Build by the means of an OpenShift Build.

Knative provides a mechanism called **BuildTemplates**, where you define a blueprint for a build, which contains the
arguments that that build might need to do its job of building the image in the end. An example of such a template can
be seen below. This template allows building images through Knative Build based on OpenShift's Build capability, so you
can use the tools you're used to while taking full advantage of Knative Build on top of it.

```yaml
apiVersion: build.knative.dev/v1alpha1
kind: BuildTemplate
metadata:
  name: openshift-builds
spec:
  parameters:
  - name: IMAGE
    description: The name of the image to push
  - name: NAME
    description: Build configuration name
  - name: IMAGE_STREAM
    description: The image stream to use as input for the build
  - name: TO_DOCKER
    description: Push the image to a Docker repository or not (true by default)
    default: "false"
  - name: DIRECTORY
    description: The directory containing the app
    default: /workspace
  - name: OC_BUILDER_IMAGE
    description: The name of the builder image to use
    default: docker.io/vdemeester/kobw-builder:0.0.1
  steps:
  - name: kobw-create-or-update
    image: "${OC_BUILDER_IMAGE}"
    args: ["create", "--name=${NAME}", "--image=${IMAGE}", "--image-stream=${IMAGE_STREAM}", "--to-docker=${TO_DOCKER}", "."]
    workingDir: "${DIRECTORY}"
    env:
      - name: NAMESPACE
        valueFrom:
          fieldRef:
            fieldPath: metadata.namespace
  - name: kobw-run
    image: "${OC_BUILDER_IMAGE}"
    args: ["run", "--name=${NAME}"]
    env:
      - name: NAMESPACE
        valueFrom:
          fieldRef:
            fieldPath: metadata.namespace
```

To achieve the desired effect, this template wraps an OpenShift Build entity to perform the build of the desired application.
To "install" that template, we need to `oc apply` it by:

```bash
$ oc apply -f build/000-build-template.yaml
```

A **Build**, as seen below, then references such a BuildTemplate and provides it with the arguments needed to perform the build.

```yaml
apiVersion: build.knative.dev/v1alpha1
kind: Build
metadata:
  name: oc-build-1
spec:
  source:
    git:
      url: https://github.com/openshift-cloud-functions/serving-function
      revision: master
  template:
    name: openshift-builds
    arguments:
    - name: IMAGE_STREAM
      value: golang:1.11
    - name: IMAGE
      value: "helloworld:latest"
    - name: NAME
      value: helloworld-build
```

In this particular case, the source code is taken from a git repository's master branch. The arguments to the template then define
that we want to build a Golang based application and want to name the image `helloworld:latest`.

Now we could go ahead and run this build on its own by applying it like the template above and using
`oc apply -f build/010-build.yaml`, but it's much more interesting to see how it's stringed together
with creating a deployment in the same step. After all, an image on it's own is worth nothing if its
not deployed.

## 2. The Serving component

The Serving component revolves around the concept of a **Service** (for clarity, it's called **KService**
throughout, because that term is vastly overloaded in the Kubernetes space). A KService is a higher level
construct that describes how an application is built and then how it's deployed in Knative.

A KService definition looks like this:

```yaml
apiVersion: serving.knative.dev/v1alpha1
kind: Service
metadata:
  name: helloworld-openshift
  namespace: myproject
spec:
  runLatest:
    configuration:
      build:
        source:
          git:
            url: https://github.com/openshift-cloud-functions/serving-function
            revision: master
        template:
          name: openshift-builds # change that
          arguments:
          - name: IMAGE_STREAM
            value: golang:1.11
          - name: IMAGE
            value: "helloworld:latest"
          - name: NAME
            value: helloworld-build
      revisionTemplate:
        metadata:
          annotations:
            alpha.image.policy.openshift.io/resolve-names: "*"
        spec:
          containerConcurrency: 1
          container:
            imagePullPolicy: Always
            image: docker-registry.default.svc:5000/myproject/helloworld:latest
            env:
            - name: BAR
              value: "bar"
```

It's very apparent that the `spec.runLatest.configuration.build` part is a one-to-one copy of the Build
manifest we created above. If we apply this specification, Knative will go ahead and build the image
through the capabilities described above. Once that's done it'll go ahead and deploy a **Revision**,
an immutable snapshot of an application. Think of it as the **Configuration** of the application at a
specific point in time.

The `revisionTemplate` part of the KService specification describes how the Pods that will contain the
application will be created and deployed. In this case, it's going to pull the image that's built
from the OpenShift internal registry.

We create the KService by, you guessed it, applying the file through `oc`:

```bash
$ oc apply -f build/020-serving.yaml
```

Now the build starts running (show in Console, link TODO) and once it finishes (Wait for finish) Knative
will produce a plain Kubernetes deployment that contains the container we specified in the RevisionSpec
above. (Show pods in Console, link TODO)

Now, to see that the service is actually running, we're going to send a request against it. To do so,
we'll get the domain of the KService:

```bash
$ oc get kservice
NAME                   DOMAIN                                       LATESTCREATED                LATESTREADY                  READY     REASON
helloworld-openshift   helloworld-openshift.myproject.example.com   helloworld-openshift-00001   helloworld-openshift-00001   True
```

The *DOMAIN* part is what we're interested in. The actual request is then sent to the entrypoint of our
servicemesh, which is listening on `$(minishift ip):32380`). Stringed together we get the following
command:

```bash
$ curl -H "Host: helloworld-openshift.myproject.example.com" "http://$(minishift ip):32380/health"

                    888 888             888
                    888 888             888
                    888 888             888
888d888 .d88b.  .d88888 88888b.  8888b. 888888
888P"  d8P  Y8bd88" 888 888 "88b    "88b888
888    88888888888  888 888  888.d888888888
888    Y8b.    Y88b 888 888  888888  888Y88b.
888     "Y8888  "Y88888 888  888"Y888888 "Y888
```

It's alive!