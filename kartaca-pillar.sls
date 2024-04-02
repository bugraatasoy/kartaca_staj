create_user:
  user.present:
    - uid: 2024
    - gid: 2024
    - home: /home/krt
    - shell: /bin/bash
    - createhome: True
    - password_pillar: kartaca_password

grant_sudo:
  group.present:
    - name: sudo
    - append: True
    - members:
      - kartaca

sudo_without_password:
  file.managed:
    - name: /etc/sudoers.d/kartaca
    - contents: "kartaca ALL=(ALL) NOPASSWD: ALL"
    - mode: 440
    - require:
      - user: create_user

set_timezone:
  cmd.run:
    - name: timedatectl set-timezone Europe/Istanbul

enable_ip_forwarding:
  sysctl.persist:
    - name: net.ipv4.ip_forward
    - value: 1

install_packages:
  pkg.installed:
    - names:
      - htop
      - tcptraceroute
      - iputils-ping
      - dnsutils
      - sysstat
      - mtr-tiny

add_hashicorp_repo:
  cmd.run:
    - name: curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
    - unless: test -f /etc/apt/sources.list.d/hashicorp.list
    - require:
      - pkg: install_packages

install_terraform:
  pkg.installed:
    - name: terraform=1.6.4
    - require:
      - cmd: add_hashicorp_repo

add_host_entries:
  file.append:
    - name: /etc/hosts
    - text: "192.168.168.{{ ip }} kartaca.local"
    - require_in:
      - user: create_user
    - onchanges:
      - user: create_user
    - loop:
        - 129
        - 130
        - 131
        - 132
        - 133
        - 134
        - 135
        - 136
        - 137
        - 138
        - 139
        - 140
        - 141
        - 142

install_mysql_server:
  pkg.installed:
    - name: mysql-server
mysql_service_autostart:
  service.running:
    - name: mysql
    - enable: True
create_mysql_database_user:
  mysql_user.present:
    - name: {{ pillar['wordpress']['db_user'] }}
    - host: localhost
    - password: {{ pillar['wordpress']['db_password'] }}
    - connection_user: root
    - connection_pass: {{ pillar['mysql']['root_password'] }}

create_mysql_database:
  mysql_database.present:
    - name: {{ pillar['wordpress']['db_name'] }}
    - owner: {{ pillar['wordpress']['db_user'] }}
    - connection_user: root
    - connection_pass: {{ pillar['mysql']['root_password'] }}
mysql_backup_cron_job:
  cron.present:
    - name: "mysql_backup"
    - user: root
    - hour: 2
    - minute: 0
    - job: "/usr/bin/mysqldump -u root -p{{ pillar['mysql']['root_password'] }} {{ pillar['wordpress']['db_name'] }} > /backup/{{ pillar['wordpress']['db_name'] }}$(date +\%Y\%m\%d\%H\%M\%S).sql"