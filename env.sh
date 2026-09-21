#!/bin/bash

set -euo pipefail

HELM_COMMAND=${HELM_COMMAND:-install}
PROJECT=${PROJECT:-garage}

info() {
	echo " 🔔 $*"
}
