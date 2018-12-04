#!/usr/bin/env bash
set -e
set -x

eval "$(minishift docker-env)"
docker image pull centos/go-toolset-7-centos7:latest
docker image pull vdemeester/kobw-builder:0.1.1
for img in $(oc get image.caching.internal.knative.dev -ojsonpath='{range .items[*]}{.spec.image}{"\n"}{end}' --all-namespaces)
do
    docker pull $img
done
