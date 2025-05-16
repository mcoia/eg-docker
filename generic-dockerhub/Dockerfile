FROM ubuntu:22.04
ARG os=jammy
# For reference: xenial = 16.04, bionic = 18.04, focal = 20.04, jammy = 22.04

EXPOSE 22
EXPOSE 80
EXPOSE 210
EXPOSE 443
EXPOSE 6001

RUN useradd user -m -s /bin/bash
RUN useradd opensrf -m -s /bin/bash
RUN useradd evergreen -m -s /bin/bash
RUN apt-get update
ENV DEBIAN_FRONTEND noninteractive
ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt-get update && apt-get install -y --no-install-recommends apt-utils

RUN apt-get -y install ansible 
RUN mkdir /egconfigs
ADD vars.yml /egconfigs/vars.yml
ADD test_vars.yml /egconfigs/test_vars.yml
RUN cd /egconfigs && ansible-playbook test_vars.yml -v

RUN apt-get -y install syslog-ng-core sendmail mailutils sendmail-bin logrotate ssh net-tools iputils-ping sudo nano make autoconf libtool git mlocate git-core ntp cron screen rsync curl vim
RUN if [ $os != "xenial"] ; then dpkg-reconfigure --frontend noninteractive tzdata ; fi

RUN mkdir -p /mnt/evergreen

# Run dockerbase script
ADD     syslog-ng.sh /egconfigs/
RUN     chmod a+xrw /egconfigs/syslog-ng.sh
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

ADD hosts /egconfigs/hosts
ADD ejabberd_jammy.yml /egconfigs/ejabberd_jammy.yml
ADD ejabberd_focal.yml /egconfigs/ejabberd_focal.yml
ADD ejabberd_bionic.yml /egconfigs/ejabberd_bionic.yml
ADD ejabberd_xenial.yml /egconfigs/ejabberd_xenial.yml

ADD logrotate_evergreen.txt /egconfigs/logrotate_evergreen.txt

ADD install_evergreen.yml /egconfigs/install_evergreen.yml
ADD evergreen_restart_services.yml /egconfigs/evergreen_restart_services.yml
ADD restart_post_boot.yml /egconfigs/restart_post_boot.yml
ADD run_tests.yml /egconfigs/run_tests.yml
RUN cd /egconfigs && ansible-playbook install_evergreen.yml -v && rm -rf /home/opensrf/repos /home/opensrf/*.tar.gz
ENTRYPOINT cd /egconfigs && ansible-playbook evergreen_restart_services.yml -vvvv && while true; do sleep 1; done
#ENTRYPOINT while true; do sleep 1; done
