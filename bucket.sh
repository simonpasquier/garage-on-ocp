#!/bin/bash

set -euo pipefail

. env.sh

echo "Creating bucket $BUCKET..."
oc exec -ti -n "$PROJECT" -c garage garage-0 -- ./garage bucket create "$BUCKET"

echo "Creating API key $BUCKET-key..."
oc exec -ti -n "$PROJECT" -c garage garage-0 -- ./garage key create "$BUCKET-key"

echo "Granting permissions to API key on $BUCKET bucket..."
oc exec -ti -n "$PROJECT" -c garage garage-0 -- ./garage bucket allow \
  --read \
  --write \
  --owner "$BUCKET" \
  --key "$BUCKET-key"
