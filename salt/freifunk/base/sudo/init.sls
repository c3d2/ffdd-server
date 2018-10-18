sudo:
  pkg.installed:
    - name: sudo
  require:
    - file: /etc/sudoers

/etc/sudoers:
  file:
    - managed
    - source: salt://sudo/etc/sudoers
    - user: root
    - group: root
    - mode: 400
    - require:
      - pkg: sudo
