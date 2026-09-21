#!/bin/bash

set -euo pipefail

. env.sh

LOGS_BUCKET=${BUCKET:-logs}
LOGS_NAMESPACE=${LOGS_NAMESPACE:-openshift-logging}
TRACES_BUCKET=${BUCKET:-traces}
TRACES_NAMESPACE=${TRACES_NAMESPACE:-observability}

# TODO: Check presence of namespaces.

info "Creating S3 buckets..."
BUCKET="${LOGS_BUCKET}" ./bucket.sh
BUCKET="${TRACES_BUCKET}" ./bucket.sh

info "Retrieving API keys..."
LOGS_ACCESS_KEY=$(oc exec -ti -n "$PROJECT" -c garage garage-0 -- ./garage key info --show-secret "$LOGS_BUCKET-key" | grep -E '^Key ID:' | sed 's/Key ID: *//g' | tr -d '\r')
if [ -z "$LOGS_ACCESS_KEY" ]; then
	info "LOGS_ACCESS_KEY not defined!"
	exit 1
fi

LOGS_SECRET_KEY=$(oc exec -ti -n "$PROJECT" -c garage garage-0 -- ./garage key info --show-secret "$LOGS_BUCKET-key" | grep -E '^Secret key:' | sed 's/Secret key: *//g' | tr -d '\r')
if [ -z "$LOGS_SECRET_KEY" ]; then
	info "LOGS_SECRET_KEY not defined!"
	exit 1
fi

TRACES_ACCESS_KEY=$(oc exec -ti -n "$PROJECT" -c garage garage-0 -- ./garage key info --show-secret "$TRACES_BUCKET-key" | grep -E '^Key ID:' | sed 's/Key ID: *//g' | tr -d '\r')
if [ -z "$TRACES_ACCESS_KEY" ]; then
	info "TRACES_ACCESS_KEY not defined!"
	exit 1
fi

TRACES_SECRET_KEY=$(oc exec -ti -n "$PROJECT" -c garage garage-0 -- ./garage key info --show-secret "$TRACES_BUCKET-key" | grep -E '^Secret key:' | sed 's/Secret key: *//g' | tr -d '\r')
if [ -z "$TRACES_SECRET_KEY" ]; then
	info "TRACES_SECRET_KEY not defined!"
	exit 1
fi

info "Creating ${LOGS_NAMESPACE}/logs-storage-credentials secret (to be used by the Loki operator)..."
oc create secret generic logs-storage-credentials -n "${LOGS_NAMESPACE}" \
	--from-literal=bucketnames="$LOGS_BUCKET" \
	--from-literal=endpoint="http://garage.$PROJECT.svc:3900" \
	--from-literal=access_key_id="$LOGS_ACCESS_KEY" \
	--from-literal=access_key_secret="$LOGS_SECRET_KEY" \
	--from-literal=forcepathstyle="true"

info "Creating ${TRACES_NAMESPACE}/traces-storage-credentials secret (to be used by the Tempo operator)..."
oc create secret generic traces-storage-credentials -n "${TRACES_NAMESPACE}" \
	--from-literal=bucket="$TRACES_BUCKET" \
	--from-literal=endpoint="http://garage.$PROJECT.svc:3900" \
	--from-literal=access_key_id="$TRACES_ACCESS_KEY" \
	--from-literal=access_key_secret="$TRACES_SECRET_KEY"
