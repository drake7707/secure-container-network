#!/bin/sh

mkdir -p /data/peers

if [[ "$1" == "server" ]]; then

  sed -e "s/{{openvpn_subnet}}/${VPN_SUBNET}/" \
      -e "s/{{openvpn_subnetmask}}/${VPN_SUBNETMASK}/" \
      /scripts/server.conf.templ > /data/server.conf

elif [[ "$1" == "client" ]]; then

  client_name=$2

  if [[ -z "${client_name}" ]]; then
    echo "Must specify client name"  1>&2
    exit 1
  fi

#  if [[ -z "${VPN_SERVER}" ]]; then
#    echo "Must specify public VPN server through environment variable VPN_SERVER" 1>&2
#    exit 1
#  fi

#  if [[ -z "${VPN_SERVER_PORT}" ]]; then
#    echo "Must specify public VPN server through environment variable VPN_SERVER_PORT" 1>&2
#    exit 1
#  fi

  peer_dir="/data/peers"

  templateFile=/scripts/client.conf.templ

  cp ${templateFile} ${peer_dir}/${client_name}.conf

#  sed -e "s/{{openvpn_server}}/${VPN_SERVER}/" \
#      -e "s/{{openvpn_server_port}}/${VPN_SERVER_PORT}/" \
#     ${peer_dir}/${client_name}.conf >  ${peer_dir}/${client_name}.conf.tmp && \
#  rm  ${peer_dir}/${client_name}.conf && mv  ${peer_dir}/${client_name}.conf.tmp  ${peer_dir}/${client_name}.conf

  awk '/\{\{additional_routes\}\}/{system("echo ${ADDITIONAL_ROUTES:-} | tr ',' \"\\n\" ");next}1'  ${peer_dir}/${client_name}.conf >  ${peer_dir}/${client_name}.conf.tmp && \
  rm  ${peer_dir}/${client_name}.conf && mv  ${peer_dir}/${client_name}.conf.tmp  ${peer_dir}/${client_name}.conf

  awk '/\{\{ca\}\}/{system("cat /data/pki/ca.crt");next}1'  ${peer_dir}/${client_name}.conf >  ${peer_dir}/${client_name}.conf.tmp && \
  rm  ${peer_dir}/${client_name}.conf && mv  ${peer_dir}/${client_name}.conf.tmp  ${peer_dir}/${client_name}.conf

  awk '/\{\{tlsauth\}\}/{system("cat /data/pki/ta.key");next}1' ${peer_dir}/${client_name}.conf > ${peer_dir}/${client_name}.conf.tmp && \
  rm  ${peer_dir}/${client_name}.conf && mv ${peer_dir}/${client_name}.conf.tmp  ${peer_dir}/${client_name}.conf

  awk "/\{\{private_key\}\}/{system(\"cat /data/pki/private/${client_name}.key\");next}1" ${peer_dir}/${client_name}.conf > ${peer_dir}/${client_name}.conf.tmp && \
  rm  ${peer_dir}/${client_name}.conf && mv ${peer_dir}/${client_name}.conf.tmp ${peer_dir}/${client_name}.conf

  awk "/\{\{cert\}\}/{system(\"openssl x509 -in /data/pki/issued/${client_name}.crt\");next}1" ${peer_dir}/${client_name}.conf >  ${peer_dir}/${client_name}.conf.tmp && \
  rm ${peer_dir}/${client_name}.conf && mv  ${peer_dir}/${client_name}.conf.tmp ${peer_dir}/${client_name}.conf

fi

