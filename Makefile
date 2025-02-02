include config

all: remove_container remove_network build create_network create_container start_container

create_repo:
	test -f Rocky-9.5-x86_64-dvd.iso || wget https://download.rockylinux.org/pub/rocky/9/isos/x86_64/Rocky-9.5-x86_64-dvd.iso
	mkdir iso
	sudo mount -o loop Rocky-9.5-x86_64-dvd.iso iso
	mkdir -p repo/rocky/9.5
	sudo rsync -a iso/ repo/rocky/9.5/
	sudo umount iso

build: Dockerfile
	sudo podman build -t bikerdanny/simple-pxe-server:0.1 .

list_networks:
	sudo podman network ls

list_containers:
	sudo podman container ls -a

create_network:
	sudo podman network create --driver=ipvlan --subnet=$(SUBNET)/$(CIDR) --gateway=$(GATEWAY) --opt parent=$(PARENT_INTERFACE) $(NETWORK_NAME)

create_container:
	sudo podman container create --name=$(CONTAINER_NAME) \
                                     --hostname=$(CONTAINER_NAME) \
                                     --tz=$(TZ) \
                                     --privileged \
                                     --env DHCP_SUBNET="$(SUBNET)" \
                                     --env DHCP_NETMASK="$(DHCP_NETMASK)" \
                                     --env DHCP_RANGE_START="$(DHCP_RANGE_START)" \
                                     --env DHCP_RANGE_END="$(DHCP_RANGE_END)" \
                                     --env DHCP_BROADCAST_ADDRESS="$(DHCP_BROADCAST_ADDRESS)" \
                                     --env DHCP_GATEWAY="$(GATEWAY)" \
                                     --env DHCP_NEXT_SERVER="$(IP)" \
				     --env PXE_CLIENT_1="$(PXE_CLIENT_1)" \
                                     --env PXE_CLIENT_2="$(PXE_CLIENT_2)" \
                                     --env PXE_CLIENT_3="$(PXE_CLIENT_3)" \
                                     --env PXE_CLIENT_4="$(PXE_CLIENT_4)" \
				     --env ROOT_PASSWORD="$(ROOT_PASSWORD)" \
				     --env APPEND_OPTIONS="$(APPEND_OPTIONS)" \
				     --volume=./repo/rocky:/var/lib/tftpboot/rocky \
				     --volume=./repo:/var/www/repo \
				     --publish=$(PORT):5000 \
                                    bikerdanny/simple-pxe-server:0.1
	sudo podman network connect --ip=$(IP) $(NETWORK_NAME) $(CONTAINER_NAME)

start_container:
	sudo podman container start $(CONTAINER_NAME)

enter_container:
	sudo podman exec -it $(CONTAINER_NAME) bash

stop_container:
	sudo podman stop $(CONTAINER_NAME)

remove_container:
	sudo podman container rm -f $(CONTAINER_NAME)

remove_network:
	sudo podman network rm -f $(NETWORK_NAME)

cleanup: remove_container remove_network
