version: '2'

{{- $netManagerImage:="leodotcloud/network-manager:v0.7.18_configurable_metadata_address" }}
{{- $metadataImage:="leodotcloud/metadata:v0.9.5_configurable_metadata_address" }}
{{- $dnsImage:="rancher/dns:v0.15.3" }}

services:
  network-manager:
    image: {{$netManagerImage}}
    privileged: true
    network_mode: host
    pid: host
    command: plugin-manager --disable-cni-setup --metadata-address ${RANCHER_METADATA_ADDRESS}
    environment:
      DOCKER_BRIDGE: docker0
      METADATA_IP: ${RANCHER_METADATA_ADDRESS}
    volumes:
    - /var/run/docker.sock:/var/run/docker.sock
    - /var/lib/docker:/var/lib/docker
    - /var/lib/rancher/state:/var/lib/rancher/state
    - /lib/modules:/lib/modules:ro
    - /run:/run
    - /var/run:/var/run:ro
    - rancher-cni-driver:/etc/cni
    - rancher-cni-driver:/opt/cni
    labels:
      io.rancher.scheduler.global: 'true'
    logging:
      driver: json-file
      options:
        max-size: 25m
        max-file: '2'
  metadata:
    cap_add:
    - NET_ADMIN
    image: {{$metadataImage}}
    network_mode: bridge
    command: start.sh rancher-metadata -reload-interval-limit=${RELOAD_INTERVAL_LIMIT} -subscribe
    environment:
      RANCHER_METADATA_ADDRESS: ${RANCHER_METADATA_ADDRESS}
    labels:
      io.rancher.sidekicks: dns
      io.rancher.container.create_agent: 'true'
      io.rancher.scheduler.global: 'true'
      io.rancher.container.agent_service.metadata: 'true'
    logging:
      driver: json-file
      options:
        max-size: 25m
        max-file: '2'
    sysctls:
      net.ipv4.conf.all.send_redirects: '0'
      net.ipv4.conf.default.send_redirects: '0'
      net.ipv4.conf.eth0.send_redirects: '0'
    cpu_period: ${CPU_PERIOD}
    cpu_quota: ${CPU_QUOTA}
  dns:
    image: {{$dnsImage}}
    network_mode: container:metadata
    command: rancher-dns --listen ${RANCHER_METADATA_ADDRESS}:53 --metadata-server=localhost --answers=/etc/rancher-dns/answers.json --recurser-timeout ${DNS_RECURSER_TIMEOUT} --ttl ${TTL}
    labels:
      io.rancher.scheduler.global: 'true'
    logging:
      driver: json-file
      options:
        max-size: 25m
        max-file: '2'
