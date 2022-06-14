#!/bin/bash

LOCALURL="https://YOURDOMAIN/eg/opac/home"

AOK=`curl -Ik $LOCALURL|grep "2 200"|wc -l`

date > check.log
# echo $AOK

EGFL=/tmp/EGFL
if [ -f $EGFL ]; then
  echo "EG restart lock found - aborting."
  exit
fi

#TENMINUTES=/tmp/tenminutes
#touch $TENMINUTES
#touch -r $TENMINUTES -d '-10 minutes' $TENMINUTES
#RECENTBOOT=$(find /proc/1/ -maxdepth 1  -name "cmdline" -not -newer ${TENMINUTES} -exec ls -1Atr {} \+ | tail -1)
#if [[ -z "${RECENTBOOT}" ]]; then
#  exit
#fi

if [ "$AOK" -gt "0" ]; then
  echo "System OK"
else
 echo "creating new EG restart lock file" >> lock.log; touch $EGFL
 date >> restart.log
 echo "system down... restarting...." >> restart.log
 ansible-playbook -vvvv -e "hosts=127.0.0.1" restart_post_boot.yml
 date >> lock.log; echo "removing EG restart lock file" >> lock.log; rm -f $EGFL
fi

