{# bind9 DNS Server #}
{% from 'config.jinja' import nodeid %}

bind:
  pkg.installed:
    - refresh: True
    - names:
      - bind9
      - bind9-host
      - bind9utils
      - dns-root-data
  service.running:
    - name: bind9
    - enable: True
    - reload: True
    - watch:
      - pkg: bind
      - file: /lib/systemd/system/bind9.service
      - file: /etc/bind/named.conf
      - file: /etc/bind/named.conf.options
      - file: /etc/bind/named.conf.default-zones
      - /etc/bind/db.root
{# DNS Master or Slave Server #}
{% if nodeid == '3' or nodeid == '15' %}
      - file: /etc/bind/named.conf.local
{% if nodeid == '3' %}
      - file: /etc/bind/zones
{% endif %}
    - require:
      - pkg: bind
      - service: S40network
      - service: S41firewall
      - file: /lib/systemd/system/bind9.service
      - file: /etc/bind/named.conf
      - file: /etc/bind/named.conf.options
      - file: /etc/bind/named.conf.local
      - file: /etc/bind/named.conf.default-zones
      - file: /var/log/named
      - /etc/bind/db.root
      - bind_reload_daemon
{# Default GW Server #}
{% else %}
      - file: /etc/bind/vpn.forwarder
    - require:
      - pkg: bind
      - service: S40network
      - service: S41firewall
      - file: /lib/systemd/system/bind9.service
      - file: /etc/bind/named.conf
      - file: /etc/bind/named.conf.options
      - file: /etc/bind/named.conf.default-zones
      - file: /etc/bind/vpn.forwarder
      - file: /var/log/named
      - /etc/bind/db.root
      - bind_reload_daemon
{% endif %}


/lib/systemd/system/bind9.service:
  file.managed:
    - source: salt://bind/lib/systemd/system/bind9.service.tmpl
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: systemd
      - pkg: bind9

bind_reload_daemon:
  cmd.run:
    - name: "systemctl daemon-reload"
    - onchanges:
      - /lib/systemd/system/bind9.service

{# check root.hints are up-to-date #}
/etc/bind/db.root:
  cmd.run:
    - name: "cp /usr/share/dns/root.hints /etc/bind/db.root"
    - onlyif: "test ! -f /etc/bind/db.root || test $(md5sum /etc/bind/db.root | awk '{ print $1 }') != $(md5sum /usr/share/dns/root.hints | awk '{ print $1 }')"
    - require:
      - pkg: bind
      - pkg: dns-root-data


{# Configuration #}
/etc/bind/named.conf:
  file.managed:
    - source: salt://bind/etc/bind/named.conf.tmpl
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: bind

/etc/bind/named.conf.options:
  file.managed:
    - source: salt://bind/etc/bind/named.conf.options.tmpl
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: bind

/etc/bind/named.conf.default-zones:
  file.managed:
    - source: salt://bind/etc/bind/named.conf.default-zones
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: bind


{% if nodeid == '3' %}
{# DNS Master Server #}
/etc/bind/named.conf.local:
  file.managed:
    - source: salt://bind/etc/bind/named.conf.local_master
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: bind

/etc/bind/zones:
  file.recurse:
    - source: salt://bind/etc/bind/zones
    - user: root
    - group: root
    - file_mode: 755
    - dir_mode: 755
    - recurse:
      - user
      - group
    - require:
      - pkg: bind

{% elif nodeid == '15' %}
{# DNS Slave Server #}
/etc/bind/named.conf.local:
  file.managed:
    - source: salt://bind/etc/bind/named.conf.local_slave
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: bind

{% else %}
{# Default GW Server #}
/etc/bind/vpn.forwarder.def:
  file.managed:
    - source: salt://bind/etc/bind/vpn.forwarder
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: bind

{# temp. file #}
/etc/bind/vpn.forwarder:
  file.managed:
    - source: salt://bind/etc/bind/vpn.forwarder
    - user: root
    - group: root
    - mode: 644
    - replace: false
    - require:
      - pkg: bind
{% endif %}


{# Logs #}
/var/log/named:
  file.directory:
    - user: bind
    - group: bind
    - require:
      - pkg: bind
