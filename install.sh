#!/bin/bash

set -euo pipefail

. env.sh

HELM_COMMAND=${HELM_COMMAND:-install}

echo "Checking presence of $PROJECT project..."
if [ -z "$(oc get project "${PROJECT}" --ignore-not-found)" ]; then
	echo "Creating $PROJECT project..."
	oc new-project garage
fi

GARAGE_UID=$(oc get project "${PROJECT}" -o json |  jq -cr '.metadata.annotations["openshift.io/sa.scc.uid-range"] | split("/")[0] | tonumber')

if [ ! -d scripts/helm ]; then
	git submodule init
	git submodule update
fi

echo "Installing garage with uid $GARAGE_UID..."
VALUES_FILE="$(mktemp)"
cat <<EOF > "$VALUES_FILE"
podSecurityContext: null
EOF
helm "$HELM_COMMAND" --namespace "${PROJECT}" garage ./garage/script/helm/garage -f "$VALUES_FILE"
oc wait -n "$PROJECT" --for=condition=Ready pods -l app.kubernetes.io/name=garage --timeout=60s

echo "Creating default layout..."
for NODE in $(oc exec -ti -n "$PROJECT" -c garage garage-0 -- ./garage status  | tail -n 3 | awk '{print $1}'); do
	echo "Assigning $NODE..."
	oc exec -ti -n "$PROJECT" -c garage garage-0 -- ./garage layout assign -z dc1 -c 1G "$NODE";
done
oc exec -ti -n "$PROJECT" -c garage garage-0 -- ./garage layout apply --version 1
