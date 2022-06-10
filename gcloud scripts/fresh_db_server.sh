#!/bin/bash
useradd user -m -s /bin/bash
useradd opensrf -m -s /bin/bash
useradd evergreen -m -s /bin/bash
mkdir /home/user/.ssh
cp authorized_keys /home/blake/.ssh/authorized_keys
chmod 700 /home/*/.ssh
chmod 600 /home/*/.ssh/*
chown user:user -R /home/user
apt-get update
apt-get -y install ssh net-tools iputils-ping sudo nano make autoconf libtool git mlocate ansible git-core ntp cron
mkdir /egconfigs
mkdir -p /mnt/evergreen
cp syslog-ng.sh /egconfigs/
/egconfigs/syslog-ng.sh
mkdir -p /etc/service/syslog-ng/run/
cp build_syslog-ng.sh /etc/service/syslog-ng/run/syslog-ng.sh
sed -i -E 's/^(\s*)system\(\);/\1unix-stream("\/dev\/log");/' /etc/syslog-ng/syslog-ng.conf
sed -i 's/^#\(SYSLOGNG_OPTS="--no-caps"\)/\1/g' /etc/default/syslog-ng
cp eg.conf /egconfigs/eg.conf
cp eg_vhost.conf /egconfigs/eg_vhost.conf
cp hosts /egconfigs/hosts
cp oils_sip.xml /egconfigs/oils_sip.xml
cp ejabberd.yml /egconfigs/ejabberd.yml
cp opensrf.xml /egconfigs/opensrf.xml
cp crontab_utility_root /egconfigs/crontab_utility_root
cp crontab_utility_opensrf /egconfigs/crontab_utility_opensrf
cp startup_base_services.yml /egconfigs/startup_base_services.yml
cp install_evergreen.yml /egconfigs/install_evergreen.yml
cp install_evergreen_database.yml /egconfigs/install_evergreen_database.yml
cp evergreen_restart_services.yml /egconfigs/evergreen_restart_services.yml
cp 16.04_master_cloud.yml /egconfigs/16.04_master_cloud.yml
cd /egconfigs && ansible-playbook install_evergreen_database.yml -v -e "hosts=127.0.0.1"


