# Example

```bash
# Get a working minishift with knative on it
# […]
# Allow default service account to schedule jobs
$ oc apply -f 000-rolebinding.yaml
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
$ oc apply -f 020-serving.yaml
# […]
$ oc get pods
# […] builds and pod should be created and running, …
# Once the build is done and service running
$ curl -H "Host: helloworld-openshift.myproject.example.com" "http://$(minishift ip):32380"
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
