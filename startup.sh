#!/bin/bash

add_pod() {
  local switch=${1}
  local container=${2}
  local ip=${3}
  local gw=${4}
  local mac=${5}
  local name="${switch}-${container}"

  ip netns add ${name}
  ip link add dev cont0 type veth peer name ${name}
  ip link set cont0 up
  ip link set ${name} up
  ip link set dev cont0 netns ${name}
  ip netns exec ${name} ip link set dev cont0 name eth0
  ip netns exec ${name} ip link set dev eth0 address ${mac}
  ip netns exec ${name} ip link set dev eth0 up
  ip netns exec ${name} ip addr add ${ip}/24 dev eth0
  ip netns exec ${name} ip route add default dev eth0 via ${gw}

  ovs-vsctl add-port br-int ${name} -- set interface ${name} external_ids:iface-id=${name}
  ovn-nbctl lsp-add ${switch} ${name} -- lsp-set-addresses ${name} "${mac} ${ip}"
}

# Start OVS
mkdir -p /var/run/openvswitch
mkdir -p /var/log/openvswitch
/usr/bin/chown root:root /var/run/openvswitch /var/log/openvswitch
/usr/share/openvswitch/scripts/ovs-ctl --no-ovs-vswitchd --no-monitor --system-id=random start
/usr/share/openvswitch/scripts/ovs-ctl --no-ovsdb-server --no-monitor --system-id=random start

mkdir -p /var/lib/ovn
mkdir -p /var/run/ovn
mkdir -p /etc/ovn
mkdir -p /usr/share/ovn
/usr/share/ovn/scripts/ovn-ctl --no-monitor start_nb_ovsdb
/usr/share/ovn/scripts/ovn-ctl --no-monitor start_sb_ovsdb
/usr/share/ovn/scripts/ovn-ctl --no-monitor start_northd
/usr/share/ovn/scripts/ovn-ctl --no-monitor start_controller

encap_ip=$(ip -4 addr show dev eth0 | grep inet | cut -f6 -d' ' | cut -f1 -d'/')
ovs-vsctl set Open_vSwitch . \
    external_ids:ovn-remote=unix:/var/run/ovn/ovnsb_db.sock \
    external_ids:ovn-encap-type=geneve \
    external_ids:ovn-encap-ip=${encap_ip}

ovn-nbctl ls-add sw1 -- set logical_switch sw1 other-config:subnet="10.0.0.0/24"
add_pod sw1 cont2 10.0.0.2 10.0.0.1 "0a:58:0a:f4:00:02"
add_pod sw1 cont3 10.0.0.3 10.0.0.1 "0a:58:0a:f4:00:03"

ovn-nbctl ls-add sw2 -- set logical_switch sw2 other-config:subnet="10.5.0.0/24"
add_pod sw2 cont5 10.5.0.5 10.5.0.1 "0a:58:0a:f4:00:05"
add_pod sw2 cont6 10.5.0.6 10.5.0.1 "0a:58:0a:f4:00:06"

ovn-nbctl lr-add router
ovn-nbctl lrp-add router rtos-sw1 "0a:58:0a:f4:00:10" "10.0.0.1/24"
ovn-nbctl lsp-add sw1 stor-sw1 -- set logical_switch_port stor-sw1 type=router options:router-port=rtos-sw1 addresses="0a\:58\:0a\:f4\:00\:10"
ovn-nbctl lrp-add router rtos-sw2 "0a:58:0a:f4:00:11" "10.5.0.1/24"
ovn-nbctl lsp-add sw2 stor-sw2 -- set logical_switch_port stor-sw2 type=router options:router-port=rtos-sw2 addresses="0a\:58\:0a\:f4\:00\:11"

tcplb=$(ovn-nbctl create load_balancer protocol=tcp)
ovn-nbctl ls-lb-add sw1 ${tcplb}
ovn-nbctl ls-lb-add sw2 ${tcplb}

ovn-nbctl set load_balancer ${tcplb} vips:"11.0.0.5\:80"="10.0.0.2:8000,10.5.0.5:8000"
ovn-nbctl set load_balancer ${tcplb} vips:"11.0.0.20\:80"=" "

ip netns exec sw1-cont2 python ./server.py 10.0.0.2 8000 sw1-cont2 &
ip netns exec sw2-cont5 python ./server.py 10.5.0.5 8000 sw2-cont5 &

alias readme=/root/README
/root/README

exec /bin/bash
