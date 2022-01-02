#!/usr/bin/env bash

set -eo pipefail

# import the deployment helpers
. $(dirname $0)/common.sh

FeeDestination="${1:-0xaDb10b8112Fac755e8ab1DfFaab116523844DD18}"
echo "Using FeeDestination = ${FeeDestination}"

# Deploy.
TokenAddr=$(deploy CliptoToken)
CliptoAddr=$(deploy CliptoExchange $TokenAddr $FeeDestination)
log "CliptoExchange deployed at:" $CliptoAddr
