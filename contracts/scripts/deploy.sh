#!/bin/bash

source .sethrc

function mynft_deploy()
{
  file_addresses=./scripts/addresses.json
  dapp build
  dapp create MyNft '"ipfs://BASE_URI/"'
  ADDRESS_MYNFT=$(getContractAddress)
  echo "{ \"nft\": \"$ADDRESS_MYNFT\" }" > $file_addresses
}

mynft_deploy "$@"
