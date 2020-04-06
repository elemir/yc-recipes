#cloud-config

datasource:
  Ec2:
    strict_id: false
ssh_pwauth: no
bootcmd:
  - 'echo 1 > /proc/sys/net/ipv4/ip_forward'
users:
  - name: ubuntu
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh-authorized-keys:
      - ${ssh_key}
write_files:
  - content: |
      network:
        version: 2
        ethernets:
          %{ for net in networks }
          eth${net.index}:
            dhcp4: true
            %{ if net.index != 0 }
            dhcp4-overrides:
              use-routes: false
            routes:
              %{ for subnet in net.subnets }
              - to: ${subnet}
                via: ${net.address}
                on-link: true
              %{ endfor }
            %{ endif }
          %{ endfor }
    path: /etc/netplan/eth.yaml
    permissions: '0755'
runcmd:
  - sleep 30
  - reboot
