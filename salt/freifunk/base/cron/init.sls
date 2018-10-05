cron:
  pkg:
    - installed

/etc/default/cron:
  file.managed:
    - source:
      - salt://cron/etc/default/cron
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: cron

# purge_old_kernels and update grub
/etc/cron.d/purge-old-kernels:
  file.managed:
    - source: salt://cron/etc/cron.d/purge-old-kernels
    - user: root
    - group: root
    - mode: 600
    - require:
      - pkg: cron
      - pkg: install_pkg
