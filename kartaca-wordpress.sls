install_nginx:
  pkg.installed:
    - names:
      - nginx
nginx_service_autostart:
  service.running:
    - name: nginx
    - enable: True
install_php_packages:
  pkg.installed:
    - names:
      - php
      - php-fpm
      - php-mysql
download_wordpress:
  cmd.run:
    - name: wget -P /tmp https://wordpress.org/latest.tar.gz

extract_wordpress:
  archive.extracted:
    - name: /var/www/wordpress2024
    - source: /tmp/latest.tar.gz
update_nginx_config:
  file.managed:
    - name: /etc/nginx/nginx.conf
    - source: salt://nginx/nginx.conf
    - require:
      - pkg: install_nginx
get_wordpress_keys:
  cmd.run:
    - name: curl -s https://api.wordpress.org/secret-key/1.1/salt/
    - shell: bash
    - require:
      - pkg: install_nginx
get_wordpress_keys:
  cmd.run:
    - name: curl -s https://api.wordpress.org/secret-key/1.1/salt/
    - shell: bash
    - require:
      - pkg: install_nginx
generate_ssl_cert:
  cmd.run:
    - name: openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/server.key -out /etc/nginx/ssl/server.crt
    - require:
      - pkg: install_nginx
configure_nginx_logrotate:
  file.managed:
    - name: /etc/logrotate.d/nginx
    - source: salt://nginx/nginx.logrotate
    - mode: 644
    - require:
      - pkg: install_nginx
restart_nginx_monthly:
  cron.present:
    - name: "restart_nginx"
    - user: root
    - day: 1
    - hour: 0
    - minute: 0
    - job: "systemctl restart nginx"
    - require:
      - pkg: install_nginx