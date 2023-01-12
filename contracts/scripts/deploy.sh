#!/bin/bash

source .sethrc

function comfyclouds_deploy()
{
  file_addresses=./scripts/addresses.json
  dapp build
  dapp create ComfyClouds '"ipfs://BASE_URI/"'
  ADDRESS_COMFYCLOUDS=$(getContractAddress)
  echo "{ \"clouds\": \"$ADDRESS_COMFYCLOUDS\" }" > $file_addresses
}

comfyclouds_deploy "$@"
