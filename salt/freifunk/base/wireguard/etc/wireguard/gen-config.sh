#!/usr/bin/env bash
### This file managed by Salt, do not edit by hand! ###
# modifies wireguard config to match firmware requirements

print_help() {
	printf 'usage: gen-config.sh [vpn0|vpn1] config-file\n'
	exit 1
}

set_vpn_if() {
	# $1 - interface number
	vpn="vpn$1"
	metric=$(( $1 + 1 ))	# used when generating config below

	# currently wg-quick (command to start vpn manually) does
	# not cope with this kind of naming. it works only when
	# config file reflects the interface name despite of that
	# a interface name can be specified in this confing file.
	#CONF="/etc/wireguard/wireguard-$vpn.conf"
	CONF="/etc/wireguard/$vpn.conf"

	#CONF="/etc/wireguard/devel-$vpn.conf"
}

case "$#" in
	2)
		case "$1" in
			vpn0)	set_vpn_if 0 ;;
			vpn1)	set_vpn_if 1 ;;
			*) print_help ;;
		esac
		shift # shift to next param (config file name)
		;;
	1) set_vpn_if 0 ;;
	*) print_help ;;
esac

input="$1"

# this code is from 'wg-quick'
# but removing spaces is fixed
read_config()
{
        shopt -s nocasematch
        while read -r line || [[ -n $line ]]; do
		# remove comments
                stripped="${line%%\#*}"

                key="${stripped%%=*}"; key="${key// /}"
                value="${stripped#*=}"; value="${value// /}"

		# reset section 
                [[ $key == "["* ]] && interface_section=0
                [[ $key == "[Interface]" ]] && interface_section=1
                if [[ $interface_section -eq 1 ]]; then
                        case "$key" in
                        Address) WG_IF_ADDRESS="$value" ; continue ;;
                        #MTU) WG_IF_MTU="$value"; continue ;;
                        DNS) WG_IF_DNS+="$value"; continue ;;
                        PrivateKey) WG_IF_PRIVATE_KEY+="$value"; continue ;;
                        esac
                fi

                [[ $key == "[Peer]" ]] && peer_section=1
                if [[ $peer_section -eq 1 ]]; then
                        case "$key" in
                        AllowedIPs) WG_PEER_ALLOWED_IPS+="$value" ; continue ;;
                        Endpoint) WG_PEER_ENDPOINT="$value"; continue ;;
                        PublicKey) WG_PEER_PUBLIC_KEY+="$value"; continue ;;
                        esac
                fi
        done < "$input"
        shopt -u nocasematch
}


read_config

# only use ipv4 as private ip
ipv4="$(echo $WG_IF_ADDRESS | awk 'match($0, /[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/) {print substr($0, RSTART, RLENGTH)}')"

cat << EOM > $CONF
# generated by $(pwd)/$(basename $0)

[Interface]
PrivateKey = $WG_IF_PRIVATE_KEY
Address = $ipv4/32
TABLE = off

PreUp = echo "forwarders { ${WG_IF_DNS//,/;}; };" > /etc/bind/vpn.forwarder.$vpn
PostUp = ip route add default dev $vpn table gateway_pool metric $metric; iptables -w -t nat -A POSTROUTING -o $vpn -j SNAT --to-source $ipv4; freifunk-gateway-check.sh 
PreDown = ip route del default dev $vpn table gateway_pool metric $metric ; iptables -w -t nat -D POSTROUTING -o $vpn -j SNAT --to-source $ipv4 ; freifunk-gateway-check.sh

[Peer]
PublicKey = $WG_PEER_PUBLIC_KEY
AllowedIPs = $WG_PEER_ALLOWED_IPS
Endpoint = $WG_PEER_ENDPOINT
PersistentKeepalive = 21

EOM


