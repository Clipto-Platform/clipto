#!/usr/bin/env bash

set -eo pipefail

# import the deployment helpers
. $(dirname $0)/common.sh

# Deploy.
CliptoAddr=$(deploy CliptoExchange)
log "CliptoExchange deployed at:" $CliptoAddr
