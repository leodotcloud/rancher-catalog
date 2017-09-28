version: '2'
services:
  ipsec:
    image: leodotcloud/net:host_net_ns
    command: start-ipsec.sh
    privileged: true
    network_mode: host
    environment:
      RANCHER_DEBUG: '${RANCHER_DEBUG}'
      IPSEC_REPLAY_WINDOW_SIZE: '${IPSEC_REPLAY_WINDOW_SIZE}'
      IPSEC_IKE_SA_REKEY_INTERVAL: '${IPSEC_IKE_SA_REKEY_INTERVAL}'
      IPSEC_CHILD_SA_REKEY_INTERVAL: '${IPSEC_CHILD_SA_REKEY_INTERVAL}'
    labels:
      io.rancher.scheduler.global: 'true'
      io.rancher.container.create_agent: 'true'
      io.rancher.container.agent_service.ipsec: 'true'
    logging:
      driver: json-file
      options:
        max-size: 25m
        max-file: '2'
  cni-driver:
    image: leodotcloud/net:host_net_ns
    privileged: true
    command: sh -c "touch /var/log/rancher-cni.log && exec tail ---disable-inotify -F /var/log/rancher-cni.log"
    network_mode: host
    pid: host
    labels:
      io.rancher.scheduler.global: 'true'
      io.rancher.network.cni.binary: 'rancher-bridge'
      io.rancher.container.dns: 'true'
    logging:
      driver: json-file
      options:
        max-size: 25m
        max-file: '2'
    network_driver:
      name: Rancher IPsec
      default_network:
        name: ipsec
        host_ports: {{ .Values.HOST_PORTS }}
        subnets:
        - network_address: $SUBNET
        dns:
        - 169.254.169.250
        dns_search:
        - rancher.internal
      cni_config:
        '10-rancher.conf':
          name: rancher-cni-network
          type: rancher-bridge
          bridge: $DOCKER_BRIDGE
          bridgeSubnet: $SUBNET
          logToFile: /var/log/rancher-cni.log
          isDebugLevel: ${RANCHER_DEBUG}
          isDefaultGateway: true
          hostNat: true
          hairpinMode: {{  .Values.RANCHER_HAIRPIN_MODE }}
          promiscMode: {{ .Values.RANCHER_PROMISCUOUS_MODE }}
          mtu: ${MTU}
          linkMTUOverhead: 98
          ipam:
            type: rancher-cni-ipam
            subnetPrefixSize: /{{ .Values.SUBNET_PREFIX }}
            logToFile: /var/log/rancher-cni.log
            isDebugLevel: ${RANCHER_DEBUG}
