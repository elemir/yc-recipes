#!/bin/sh

kubectl -n sysctl-tuner delete -f sysctl-tuner-operator.yaml 2>/dev/null || echo "resources already deleted"
kubectl delete ns sysctl-tuner 2>/dev/null || echo "namespace 'sysctl-tuner' already deleted"

# remove images
registry_id=$(yc container registry get --name sysctl-tuner --format json 2>/dev/null | jq -r ".id" 2>/dev/null)

if [ -z "${registry_id}" ]; then
    echo "registry already removed"
    exit 0
fi

yc container image list --repository-name ${registry_id}/tuner --format json | jq -r '.[].id' | while read id; do
  yc container image delete ${id}
done

yc container registry delete ${registry_id} || echo "registry 'sysctl-tuner' looks non empty"
