# Example

```bash
# Get a working minishift with knative (serving and build at least) on it
# […]
# We will need our user to have the correct right
# FIXME(vdemeester) this rights are too much
$ oc policy add-role-to-user admin system:serviceaccount:myproject:default
$ oc import-image -n openshift golang --from=centos/go-toolset-7-centos7 --confirm
$ oc import-image -n openshift golang:1.11 --from=centos/go-toolset-7-centos7 --confirm
# Create the build template
$ oc apply -f 000-build-template.yaml
# Create a build (and validate it work)
$ oc apply -f 010-build.yaml
# […]
$ oc get pods
$ oc get build
$ oc get buildconfig
# Clean the build (for now)
$ oc delete -f 010-build.yaml
# Create a serving that will depend on a build (creating this one too)
# update the knative config map to add the internal registry as "safe"
# to not resolve.
$ val=$(oc -n knative-serving get cm config-controller -o yaml | yq -r .data.registriesSkippingTagResolving | awk '{print $1",docker-registry.default.svc:5000"}')
$ oc -n knative-serving get cm config-controller -oyaml | yq w - data.registriesSkippingTagResolving $val | oc apply -f - 
$ oc apply -f 020-serving.yaml
# […]
$ oc get pods
# […] builds and pod should be created and running, …
# Once the build is done and service running
$ curl -H "Host: helloworld-openshift.myproject.example.com" http://$(minishift ip):32380
GET / HTTP/1.1
Host: helloworld-openshift.myproject.example.com
Accept: */*
Accept-Encoding: gzip
User-Agent: curl/7.61.0
X-B3-Sampled: 1
X-B3-Spanid: a4b4cdd9605b74b8
X-B3-Traceid: a4b4cdd9605b74b8
X-Envoy-Expected-Rq-Timeout-Ms: 60000
X-Envoy-Internal: true
X-Forwarded-For: 172.17.0.1, 127.0.0.1
X-Forwarded-Proto: http
X-Request-Id: 9279c0f6-dd3c-986a-a17c-834db6b67d38
```
