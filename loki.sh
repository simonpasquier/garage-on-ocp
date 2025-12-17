#!/bin/bash

set -euo pipefail

. env.sh

BUCKET=${BUCKET:-loki}

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

oc create secret generic logging-loki-garage -n openshift-logging \
	--from-literal=bucketnames="$BUCKET" \
	--from-literal=endpoint="http://garage.$PROJECT.svc:3900" \
	--from-literal=access_key_id="$ACCESS_KEY" \
	--from-literal=access_key_secret="$SECRET_KEY" \
	--from-literal=forcepathstyle="true"
echo "Secret openshift-logging/logging-loki-garage created..."
