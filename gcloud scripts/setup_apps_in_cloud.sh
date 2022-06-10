# First create a single-zone cluster:
# https://cloud.google.com/kubernetes-engine/docs/how-to/creating-a-cluster
# 
# Then get list of app servers
echo `kubectl get po|grep -v NAME | awk '{print $1}'|while read line ; do kubectl describe po/$line ; done |grep IP | awk '{print $2}'| tr '\n' ' '`
kubectl create -f nfs-pv.yaml
kubectl create -f nfs-pvc.yaml
kubectl create -f create_apps_service.yml
kubectl create -f create_apps.yml
