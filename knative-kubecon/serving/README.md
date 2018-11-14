After having applied the service from the build demo.

1. Open `echo "http://$(minishift ip):9000/k8s/ns/myproject/pods"` to see your pods.
2. Open `echo "https://$(oc get routes kiali -n istio-system -o jsonpath='{.spec.host}')/console/service-graph/myproject?layout=cose-bilkent&duration=60&edges=requestsPercentOfTotal&graphType=versionedApp"` to visualize the application's graph. Default username/password is "admin/admin".

## Optional:

To access Grafana, open:

```
echo "http://$(oc get routes grafana -n istio-system -o jsonpath='{.spec.host}')/d/UbsSZTDik/istio-workload-dashboard?refresh=10s&orgId=1&var-namespace=myproject&var-workload=helloworld-openshift-python-test-00001-deployment&var-srcns=All&var-srcwl=All&var-dstsvc=All"
```


## TODO:

- Adjust the links to point to the right namespace/app.
- Create a buggy app-version, which is fixable.
- Don't create a Service, but create route/configuration independently to be able to traffic split appropriately (should we use manual/release mode here maybe?)