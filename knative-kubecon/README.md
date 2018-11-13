# Knative and OpenShift Demo for KubeCon

A demo of Knative and OpenShift for KubeCon.

## Minishift setup for the demo

### Minishift machine setup

```
$ minishift profile set knative-demo
$ minishift config set memory 8GB
$ minishift config set cpus 4
# from istio setup
$ minishift addon enable admin-user
$ minishift addon enable anyuid
# end istio setup
$ minishift start
$ eval $(minishift oc-env)
$ eval $(minishift docker-env)
$ oc login -u system:admin
```

### Prepare setup

```
# this is included in the knative-operators repo
$ ./knative-operators/etc/scripts/prep-knative.sh
```

### Istio installation
```
$ git clone https://github.com/minishift/minishift-addons
$ minishift addon install ./minishift-addons/add-ons/istio
$ minishift addon enable istio
$ minishift addon apply istio
```

### OLM installation

```
$ git clone https://github.com/operator-framework/operator-lifecycle-manager.git
$ oc create -f operator-lifecycle-manager/deploy/okd/manifests/latest/
```

### OLM interface startup

```
# part of the OLM repo
$ ./operator-lifecycle-manager/scripts/run_console_local.sh
```

### OCF operators

```
$ oc apply -f https://raw.githubusercontent.com/openshift-cloud-functions/knative-operators/master/knative-operators.catalogsource.yaml
$ oc new-project knative-build
$ oc new-project knative-serving
$ oc new-project knative-eventing
```