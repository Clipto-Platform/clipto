#!/usr/bin/env bash

set -eo pipefail

# import the deployment helpers
. $(dirname $0)/common.sh

# Please set the fee destination prior to deployment
# FeeDestination="${1:-0x800852637eFA2e5C21C3E82FaD8CcdC708786817}"

# Deploy.
TokenAddr=$(deploy CliptoToken)
CliptoAddr=$(deploy CliptoExchange $TokenAddr $FeeDestination)
log "CliptoExchange deployed at:" $CliptoAddr
