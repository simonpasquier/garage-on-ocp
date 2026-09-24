#!/bin/bash

set -euo pipefail

. env.sh

info "Checking presence of $PROJECT project..."
if [ -z "$(oc get project "${PROJECT}" --ignore-not-found)" ]; then
	info "Creating $PROJECT project..."
	oc new-project "${PROJECT}"
fi

GARAGE_UID=$(oc get project "${PROJECT}" -o json |  jq -cr '.metadata.annotations["openshift.io/sa.scc.uid-range"] | split("/")[0] | tonumber')

if [ ! -d garage/scripts/helm ]; then
	git submodule init
	git submodule update
fi

info "Installing garage with uid $GARAGE_UID..."
VALUES_FILE="$(mktemp)"
cat <<EOF > "$VALUES_FILE"
podSecurityContext: null
monitoring:
  metrics:
    enabled: true
EOF
info "Helm paramters:"
cat "$VALUES_FILE"

helm "$HELM_COMMAND" --namespace "${PROJECT}" garage ./garage/script/helm/garage -f "$VALUES_FILE"
info "Waiting a few seconds for the pods to start..."
sleep 30

info "Waiting for pods to be ready..."
oc wait -n "$PROJECT" --for=condition=Ready pods -l app.kubernetes.io/name=garage --timeout=60s

info "Current status..."
oc exec -ti -n "${PROJECT}" -c garage garage-0 -- ./garage status

info "Creating default layout..."
for NODE in $(oc exec -ti -n "$PROJECT" -c garage garage-0 -- ./garage status  | tail -n 3 | awk '{print $1}'); do
	info "Assigning $NODE..."
	oc exec -ti -n "$PROJECT" -c garage garage-0 -- ./garage layout assign -z dc1 -c 1G "$NODE";
done

info "Showing staged layout..."
oc exec -ti -n "$PROJECT" -c garage garage-0 -- ./garage layout show

info "Commiting layout changes..."
oc exec -ti -n "$PROJECT" -c garage garage-0 -- ./garage layout apply --version 1
