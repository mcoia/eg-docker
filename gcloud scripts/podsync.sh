#!/bin/bash

export GOOGLE_APPLICATION_CREDENTIALS="/path/to/key.json"

PATH_TO_KUBECTL="/root/google-cloud-sdk/bin/kubectl"
PATH_TO_GCLOUD="/root/google-cloud-sdk/bin/gcloud"
DOCKER_CONTAINER_NAME=meapps
PODNUM=`$PATH_TO_KUBECTL get po|grep -v "RESTARTS" | wc -l`
PROJECT_ID=evergreen-1470164758084

$PATH_TO_GCLOUD container clusters get-credentials $DOCKER_CONTAINER_NAME --zone us-central1-c --project $PROJECT_ID

INSTANCENUM=`$PATH_TO_GCLOUD compute instance-groups list|grep -v "INSTANCES" | awk '{print $6}'`

echo PODNUM = $PODNUM
echo INSTANCENUM = $INSTANCENUM

if [ "$INSTANCENUM" -gt "$PODNUM" ];
  then
    echo "less pods"
	echo "going up to $INSTANCENUM"
    $PATH_TO_KUBECTL scale rc $DOCKER_CONTAINER_NAME --replicas=$INSTANCENUM
	rm /tmp/podsync_date
    exit;
elif [ "$PODNUM" -gt "$INSTANCENUM" ];
	then
	if [ $INSTANCENUM == 1 ];
	then
		echo "Winding down to 1 pod"
		if [ -a /tmp/podsync_date ];
		then
			while read -r line
			do
				recordeddate="$line"
			done < "/tmp/podsync_date"
			echo "Read date $line from /tmp/podsync_date"
			CURRENTDATE=`date +%s`
			SECONDS=`expr $CURRENTDATE - $recordeddate`
			echo "Current date is $SECONDS seconds later than $line"
			if [ "$SECONDS" -gt "599" ]
			then
				echo "Ok - it's been 10 minutes, decreasing the pods to 1"
				$PATH_TO_KUBECTL scale rc $DOCKER_CONTAINER_NAME --replicas=1
				rm /tmp/podsync_date
			fi
		else
			echo "recording the exact date to /tmp/podsync_date"
			date +%s > /tmp/podsync_date
		fi
    else
		echo "going down to $INSTANCENUM"
		$PATH_TO_KUBECTL scale rc $DOCKER_CONTAINER_NAME --replicas=$INSTANCENUM
		rm /tmp/podsync_date
	fi
	
else
    echo "Perfect match"
	rm /tmp/podsync_date
fi
