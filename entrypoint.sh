#!/bin/bash

# DHCP server
cat << EOF > /etc/dhcp/dhcpd.conf 
subnet ${DHCP_SUBNET} netmask ${DHCP_NETMASK} {
  range ${DHCP_RANGE_START} ${DHCP_RANGE_END};
  option broadcast-address ${DHCP_BROADCAST_ADDRESS};
  option routers ${DHCP_GATEWAY};
  filename "pxelinux.0";
  next-server ${DHCP_NEXT_SERVER};
}
EOF

for client in ${!PXE_CLIENT_@}; do
  host=(${!client//,/ })
  echo "" >> /etc/dhcp/dhcpd.conf
  echo "host ${host[0]} {" >> /etc/dhcp/dhcpd.conf
  echo "  hardware ethernet ${host[1]};" >> /etc/dhcp/dhcpd.conf
  echo "  fixed-address ${host[2]};" >> /etc/dhcp/dhcpd.conf
  echo "}" >> /etc/dhcp/dhcpd.conf
done

# PXE server
cat << EOF1 > /var/lib/tftpboot/pxelinux.cfg/default
default menu.c32
prompt 0
timeout 30
ONTIMEOUT local

menu title PXE Boot Menu

label local
  menu label Boot Local Disk
  localboot 0

label rocky9
  menu label Rocky Linux 9 Installer
  kernel rocky/9.5/images/pxeboot/vmlinuz
  append initrd=rocky/9.5/images/pxeboot/initrd.img inst.repo=http://${DHCP_NEXT_SERVER}/rocky/9.5/ inst.ks=http://${DHCP_NEXT_SERVER}/rocky9.ks
EOF1

cat << EOF > /opt/rest/deploy.sh
#!/bin/bash

if [[ "\${#}" != "1" ]]; then
	        echo "Usage: \${0} <mac>"
		        exit 1
fi

MAC="\${1}"
MAC_PXE="01-\$(echo "\${MAC}" | tr '[:upper:]' '[:lower:]' | tr ':' '-')"

cat << 'EOF2' > /var/lib/tftpboot/pxelinux.cfg/\${MAC_PXE}
default menu.c32
prompt 0
timeout 5
ONTIMEOUT rocky9

menu title PXE Boot Menu

label rocky9
  menu label Rocky Linux 9 Installer
  kernel rocky/9.5/images/pxeboot/vmlinuz
  append initrd=rocky/9.5/images/pxeboot/initrd.img inst.repo=http://${DHCP_NEXT_SERVER}/rocky/9.5/ inst.ks=http://${DHCP_NEXT_SERVER}/rocky9.ks
EOF2

echo "OK"
EOF
chmod +x /opt/rest/deploy.sh

cat << EOF > /var/www/repo/rocky9.ks
# Use graphical install
graphical
repo --name="AppStream" --baseurl=http://${DHCP_NEXT_SERVER}/rocky/9.5/AppStream

%addon com_redhat_kdump --enable --reserve-mb='auto'

%end

# Keyboard layouts
keyboard --xlayouts='de (nodeadkeys)'
# System language
lang de_DE.UTF-8

# Network information
$(for client in ${!PXE_CLIENT_@}; do host=(${!client//,/ }); echo "network --bootproto=static --dhcpclass=anaconda-Linux --device=${host[1]} --gateway=${DHCP_GATEWAY} --hostname=${host[0]} --ip=${host[2]} --nameserver=8.8.8.8 --netmask=${DHCP_NETMASK} --noipv6 --activate";done)
#network --bootproto=static --dhcpclass=anaconda-Linux --device=BC:24:11:DA:A2:7E --gateway=10.0.4.1 --ip=10.0.4.31 --nameserver=8.8.8.8 --netmask=255.255.255.0 --noipv6 --activate
#network --bootproto=static --dhcpclass=anaconda-Linux --device=BC:24:11:D4:D5:18 --gateway=10.0.4.1 --ip=10.0.4.32 --nameserver=8.8.8.8 --netmask=255.255.255.0 --noipv6 --activate
#network --hostname=pxe-client

# Use network installation
url --url="http://${DHCP_NEXT_SERVER}/rocky/9.5/BaseOS"

%packages
@^minimal-environment
#@^graphical-server-environment

%end

# Run the Setup Agent on first boot
firstboot --enable

# Generated using Blivet version 3.6.0
ignoredisk --only-use=sda
autopart
# Partition clearing information
clearpart --drives=sda --all
# Reboot after installation
reboot

# System timezone
timezone Europe/Berlin --utc

# Root password
rootpw --iscrypted --allow-ssh $(mkpasswd --method=sha-512 ${ROOT_PASSWORD})

%post --nochroot
curl http://${DHCP_NEXT_SERVER}:5000/finish
%end
EOF

# HTTP server
cat << EOF > /etc/httpd/conf.d/repo.conf
<VirtualHost *:80>
    ServerName repo
    DocumentRoot /var/www/repo

    <Directory /var/www/repo>
        Options -Indexes +FollowSymLinks
        AllowOverride All
    </Directory>

    ErrorLog /var/log/httpd/repo-error.log
    CustomLog /var/log/httpd/repo-access.log combined
</VirtualHost>
EOF

cd /opt/rest
flask run --host=0.0.0.0 --debug &

exec ${@}
