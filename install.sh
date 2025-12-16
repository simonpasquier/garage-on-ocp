#!/bin/bash

set -euo pipefail

PROJECT=${PROJECT:-garage}
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
podSecurityContext:
  runAsUser: $GARAGE_UID
  runAsGroup: $GARAGE_UID
  fsGroup: $GARAGE_UID
EOF
helm "$HELM_COMMAND" --namespace "${PROJECT}" garage ./garage/script/helm/garage -f "$VALUES_FILE"
oc wait -n "$PROJECT" --for=condition=Ready pods -l app.kubernetes.io/name=garage --timeout=60s
