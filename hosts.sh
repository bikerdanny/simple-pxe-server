#!/bin/bash

function getstatus() {
  mac="${1}"
  mac_pxe="01-$(echo "${mac}" | tr '[:upper:]' '[:lower:]' | tr ':' '-')"
  status="unknown"
  if [[ -f "/var/lib/tftpboot/pxelinux.cfg/${mac_pxe}" ]]; then
    status="active"
  else
    status="inactive"
  fi
  echo "${status}"
}

for client in ${!PXE_CLIENT_@}; do
  host=(${!client//,/ })
  status=$(getstatus ${host[1]})
  export $client="${!client},${status}"
done

for client in ${!PXE_CLIENT_@}; do echo "${!client}"; done | jq --raw-input --slurp '{hosts: split("\n") | .[:-1] | map(split(",")) | map({host: .[0], mac: .[1], ip: .[2], status: .[3]})}'
