FROM rockylinux:9

RUN dnf install -y systemd

# DHCP server
RUN dnf install -y dhcp-server
ENV DHCP_SUBNET="10.0.0.0"
ENV DHCP_NETMASK="255.255.255.0"
ENV DHCP_RANGE_START="10.0.0.100"
ENV DHCP_RANGE_END="10.0.0.200"
ENV DHCP_BROADCAST_ADDRESS="10.0.0.255"
ENV DHCP_GATEWAY="10.0.0.1"
ENV DHCP_NEXT_SERVER="10.0.0.254"
RUN systemctl enable dhcpd

# TFTP server
RUN dnf install -y tftp-server
RUN systemctl enable tftp

# PXE server
RUN dnf install -y syslinux mkpasswd
RUN mkdir /var/lib/tftpboot/pxelinux.cfg
RUN cp /usr/share/syslinux/pxelinux.0 /var/lib/tftpboot/.
RUN cp /usr/share/syslinux/ldlinux.c32 /var/lib/tftpboot/.
RUN cp /usr/share/syslinux/menu.c32 /var/lib/tftpboot/.
RUN cp /usr/share/syslinux/libutil.c32 /var/lib/tftpboot/.
#COPY ./default /var/lib/tftpboot/pxelinux.cfg/default

# HTTP server
RUN dnf install -y httpd
RUN mkdir /var/www/repo
RUN systemctl enable httpd

## Cockpit
#RUN dnf install -y cockpit
#RUN systemctl enable cockpit.socket

# REST API
RUN dnf install -y python3-pip net-tools jq
RUN pip3 install flask flask_cors
RUN mkdir -p /opt/rest/templates
COPY ./app.py /opt/rest/app.py
#COPY ./deploy.sh /opt/rest/deploy.sh
COPY ./finish.sh /opt/rest/finish.sh
COPY ./hosts.sh /opt/rest/hosts.sh
COPY ./templates/index.html /opt/rest/templates/index.html

COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

CMD ["/usr/sbin/init"]
