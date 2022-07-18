FROM ubuntu:20.04
ARG os=focal
# For reference: xenial = 16.04, bionic = 18.04, focal = 20.04

EXPOSE 22
EXPOSE 80
EXPOSE 210
EXPOSE 443
EXPOSE 6001

RUN useradd user -G sudo -m -s /bin/bash
RUN useradd opensrf -m -s /bin/bash
RUN useradd evergreen -m -s /bin/bash
ARG DEBIAN_FRONTEND=noninteractive
ARG TZ=America/New_York
RUN apt-get update && apt-get install -y --no-install-recommends apt-utils
RUN apt-get -y install syslog-ng-core sendmail mailutils sendmail-bin logrotate ssh net-tools iputils-ping sudo nano pkgconf make autoconf libtool git mlocate ansible git-core ntp cron screen rsync curl tzdata vim-tiny 

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN [ "dpkg-reconfigure", "--frontend=noninteractive", "tzdata" ]·
WORKDIR /egconfigs
RUN [ "mkdir" , "-p" , "/mnt/evergreen" ]

COPY  . ./
COPY [ "./build_syslog-ng.sh", "/etc/service/syslog-ng/run/syslog-ng.sh" ]
COPY [ "./sudo_group", "/etc/sudoers.d" ]
RUN  [ "chmod", "440", "/etc/sudoers.d/sudo_group" ]

# Replace the system() source because inside Docker we can't access /proc/kmsg.
# https://groups.google.com/forum/#!topic/docker-user/446yoB0Vx6w
RUN	sed -i -E 's/^(\s*)system\(\);/\1unix-stream("\/dev\/log");/' /etc/syslog-ng/syslog-ng.conf
# Uncomment 'SYSLOGNG_OPTS="--no-caps"' to avoid the following warning:
# syslog-ng: Error setting capabilities, capability management disabled; error='Operation not permitted'
# http://serverfault.com/questions/524518/error-setting-capabilities-capability-management-disabled#
RUN	sed -i 's/^#\(SYSLOGNG_OPTS="--no-caps"\)/\1/g' /etc/default/syslog-ng

# Clean up system
RUN apt-get clean && apt-get autoclean && apt-get autoclean && rm -rf /var/tmp/* /tmp/* /var/lib/apt/lists/* build_syslog-ng.sh sudo_group

CMD [ "whoami" ]

CMD echo RUN ansible-playbook install_evergreen-mini.yml -v -e "host=127.0.0.1" -c local 
RUN ansible-playbook install_evergreen.yml -v -e "host=127.0.0.1" -c local 
#ENTRYPOINT cd /egconfigs && ansible-playbook evergreen_restart_services.yml -vvvv -e "hosts=127.0.0.1" && while true; do sleep 1; done
ENTRYPOINT while true; do sleep 1; done


#ENTRYPOINT while true; do sleep 1; done
