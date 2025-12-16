#!/bin/bash

set -euo pipefail

. env.sh

ACCESS_KEY=$(oc exec -ti -n "$PROJECT" -c garage garage-0 -- ./garage key info --show-secret "$BUCKET-key" | grep -E '^Key ID:' | sed 's/Key ID: //g')
if [ -z "$ACCESS_KEY" ]; then
	echo "ACCESS_KEY not defined!"
	exit 1
fi

SECRET_KEY=$(oc exec -ti -n "$PROJECT" -c garage garage-0 -- ./garage key info --show-secret "$BUCKET-key" | grep -E '^Secret key:' | sed 's/Secret key: //g' )
if [ -z "$SECRET_KEY" ]; then
	echo "SECRET_KEY not defined!"
	exit 1
fi

SECRET=$(cat <<EOF
type: S3
config:
  bucket: "$BUCKET"
  access_key: ""
  secret_key: "thanos-secret"
  endpoint: "garage.$PROJECT.svc:3900"
  insecure: true
  trace:
    enable: false
EOF
)

oc create secret generic -n thanos-operator-system thanos-object-storage --from-literal=thanos.yaml="$SECRET"
echo "Secret thanos-operator-system/thanos-object-storage created..."
