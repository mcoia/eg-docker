FROM ubuntu:16.04

EXPOSE 22
EXPOSE 80
EXPOSE 210
EXPOSE 443
EXPOSE 6001
EXPOSE 7680
EXPOSE 7682

RUN useradd user -m -s /bin/bash
RUN useradd opensrf -m -s /bin/bash
RUN useradd evergreen -m -s /bin/bash
RUN mkdir /home/user/.ssh
ADD authorized_keys /home/user/.ssh/authorized_keys
RUN chmod 700 /home/*/.ssh
RUN chmod 600 /home/*/.ssh/*
RUN chown user:user -R /home/user
RUN apt-get update
RUN apt-get -y install sendmail mailutils sendmail-bin logrotate ssh net-tools iputils-ping sudo nano make autoconf libtool git mlocate ansible git-core ntp cron screen
RUN mkdir /egconfigs
RUN mkdir -p /mnt/evergreen

# Run dockerbase script
ADD     syslog-ng.sh /egconfigs/
RUN     /egconfigs/syslog-ng.sh

# Add syslog-ng into runit
ADD     build_syslog-ng.sh /etc/service/syslog-ng/run/syslog-ng.sh
# Replace the system() source because inside Docker we can't access /proc/kmsg.
# https://groups.google.com/forum/#!topic/docker-user/446yoB0Vx6w
RUN	sed -i -E 's/^(\s*)system\(\);/\1unix-stream("\/dev\/log");/' /etc/syslog-ng/syslog-ng.conf
# Uncomment 'SYSLOGNG_OPTS="--no-caps"' to avoid the following warning:
# syslog-ng: Error setting capabilities, capability management disabled; error='Operation not permitted'
# http://serverfault.com/questions/524518/error-setting-capabilities-capability-management-disabled#
RUN	sed -i 's/^#\(SYSLOGNG_OPTS="--no-caps"\)/\1/g' /etc/default/syslog-ng



ADD eg.conf /egconfigs/eg.conf
ADD eg_vhost.conf /egconfigs/eg_vhost.conf
ADD hosts /egconfigs/hosts
ADD oils_sip.xml /egconfigs/oils_sip.xml
ADD ejabberd.yml /egconfigs/ejabberd.yml
ADD opensrf.xml /egconfigs/opensrf.xml
ADD crontab_utility_root /egconfigs/crontab_utility_root
ADD crontab_utility_opensrf /egconfigs/crontab_utility_opensrf
ADD startup_base_services.yml /egconfigs/startup_base_services.yml
ADD logrotate_evergreen.txt /egconfigs/logrotate_evergreen.txt
add auth_keys_tunnel /egconfigs/auth_keys_tunnel


ADD 16.04_master_cloud.yml /egconfigs/16.04_master_cloud.yml
ADD install_evergreen.yml /egconfigs/install_evergreen.yml
ADD evergreen_restart_services.yml /egconfigs/evergreen_restart_services.yml
RUN cd /egconfigs && ansible-playbook install_evergreen.yml -v -e "hosts=127.0.0.1"
ENTRYPOINT cd /egconfigs && ansible-playbook evergreen_restart_services.yml -vvvv -e "hosts=127.0.0.1" && while true; do sleep 1; done
#ENTRYPOINT cd /egconfigs && ansible-playbook startup_base_services.yml -vvvv -e "hosts=127.0.0.1" && while true; do sleep 1; done