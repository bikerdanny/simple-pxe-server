#!/bin/bash

if [[ "${#}" != "1" ]]; then
	echo "Usage: ${0} <ip>"
	exit 1
fi

IP="${1}"
MAC="$(arp -a ${IP} | cut -d' ' -f4)"
MAC_PXE_FORMAT="01-$(echo "${MAC}" | sed 's/:/-/g')"

#echo "${IP}"
#echo "${MAC}"
#echo "${MAC_PXE_FORMAT}"

rm -f /var/lib/tftpboot/pxelinux.cfg/${MAC_PXE_FORMAT}

echo "OK"
