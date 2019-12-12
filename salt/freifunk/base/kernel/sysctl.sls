{# sysctl #}
{% set sysctld = "/etc/sysctl.d" %}

net.ipv4.conf.all.forwarding:
  sysctl.present:
    - value: 1
    - config: {{ sysctld }}/forward.conf

{# bmxd doesnt like rp_filter #}
net.ipv4.conf.default.rp_filter:
  sysctl.present:
    - value: 0
    - config: {{ sysctld }}/net.conf
net.ipv4.conf.all.rp_filter:
  sysctl.present:
    - value: 0
    - config: {{ sysctld }}/net.conf

net.ipv4.tcp_syncookies:
  sysctl.present:
    - value: 1
    - config: {{ sysctld }}/net.conf
    - unless: "[ ! -e /proc/sys/net/ipv4/tcp_syncookies ]"

{# increase conntrack hash table #}
net.netfilter.nf_conntrack_max:
  sysctl.present:
    - value: 200000
    - config: {{ sysctld }}/net.conf
    - unless: "[ ! -e /proc/sys/net/netfilter/nf_conntrack_max ]"
