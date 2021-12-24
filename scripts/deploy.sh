#!/usr/bin/env bash

set -eo pipefail

# import the deployment helpers
. $(dirname $0)/common.sh

# Deploy.
TokenAddr=$(deploy CliptoToken)
CliptoAddr=$(deploy CliptoExchange $TokenAddr)
log "CliptoExchange deployed at:" $CliptoAddr
