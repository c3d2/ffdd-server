{% from 'config.jinja' import install_dir, ct_bmxd %}

/usr/local/src/bmxd:
  file.recurse:
    - source:
      - salt://bmxd/compiled-tools/bmxd
    - user: freifunk
    - group: freifunk
    - file_mode: 775
    - dir_mode: 775
    - require:
      - pkg: devel
      - user: freifunk

/usr/local/bin/freifunk-get_bmxd_revision.sh:
  file.managed:
    - contents: |
        #!/usr/bin/env bash
        cd {{ install_dir }}{{ ct_bmxd }}
        { export LC_ALL=C;
          find -type f -exec wc -c {} \; | sort; echo;
          find -type f -exec md5sum {} + | sort; echo;
          find . -type d | sort; find . -type d | sort | md5sum;
        } | md5sum | sed -e 's/^\(.\{10\}\).*/\1/' > /usr/local/src/bmxd/revision_version
    - user: root
    - group: root
    - mode: 755


get_bmxd_revision:
  cmd.run:
    - name: "/usr/local/bin/freifunk-get_bmxd_revision.sh"
    - onchanges:
      - file: /usr/local/src/bmxd

compile_bmxd:
  cmd.run:
    - name: "cd /usr/local/src/bmxd/ && make && make strip && cp -f bmxd /usr/local/bin/"
    - require:
      - file: /usr/local/src/bmxd
    - onchanges:
      - file: /usr/local/src/bmxd


/etc/init.d/S52batmand:
  file.managed:
    - source: salt://bmxd/etc/init.d/S52batmand
    - user: root
    - group: root
    - mode: 755

rc.d_S52batmand:
  cmd.run:
    - name: /usr/sbin/update-rc.d S52batmand defaults
    - require:
      - file: /etc/init.d/S52batmand
    - onchanges:
      - file: /etc/init.d/S52batmand


S52batmand:
  service:
    - running
    - enable: True
    - restart: True
    - watch:
      - file: /etc/init.d/S52batmand
      - file: /usr/local/src/bmxd
      - service: S41firewall
      - service: S53backbone-fastd2
    - require:
      - file: /etc/init.d/S52batmand
      - file: /usr/local/src/bmxd
      - service: S40network
      - service: S41firewall
      - service: S53backbone-fastd2
