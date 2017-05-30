#!/bin/bash
# ./generate-kubecfg.sh -k <kube cluster name> -a <apiserver:port> -c </path/to/ca.pem> [-u <username>] [-t <gitlab access token>] [-h]

# Exit on error
abort(){
  echo $1 && exit 1
}

# Prerequistes
for i in jq kubectl
do
 if ! which -s $i; then
  abort "$i is not instaled." 
 fi
done

help(){
  echo "./generate-kubecfg.sh -k <kube cluster name> -a <apiserver:port> -c </path/to/ca.pem> [-u <username>] [-t <gitlab access token>] [-h]"
  echo "You can use export USERNAME=<username>; export GITLAB_TOKEN=<gitlab token> to set usename and GitLab token." 
  exit 0
}

# Take environment variables as default for userName and gitLabToken
gitlabToken="${GITLAB_TOKEN:-}"
userName="${USERNAME:-}"

while getopts "k:a:c:u:t:h" OPTION
do
  case $OPTION in
    k)
      clusterName=$OPTARG
      ;;
    a)
      apiServer=$OPTARG
      apiServer="${OPTARG#https://}"
      apiServer="${apiServer#http://}"
      ;;
    c)
      caPem=$OPTARG
      ;;
    u)
      userName=$OPTARG
      ;;
    t)
      gitlabToken=$OPTARG
      ;;
    [h?])
      help
      ;;
 esac
done

if [[ -z $userName || -z $clusterName || -z $apiServer || -z $gitlabToken || -z "$caPem" ]]; 
then
  help
fi

if ! kubectl config get-clusters | grep -q "^$clusterName$"; 
then
  abort "No cluster $clusterName."
fi

kubePath=$HOME/.kube
kubeConfig=$kubePath/config
mkdir -p $HOME/.kube

# Verift ApiServer cert
if ! openssl x509 -noout -text -in $caPem ; then
  abort "Invalid cert."
fi

echo kubectl config set-cluster kubernetes...
kubectl config set-cluster ${clusterName} \
    --certificate-authority=${caPem} \
    --embed-certs=true \
    --server=https://${apiServer}

echo kubectl config set-credentials $username...
kubectl config set-credentials $userName --token=$gitlabToken

context=${clusterName}-${userName}

echo kubectl config set-context ${context} ...
kubectl config set-context ${context} \
   --cluster=${clusterName} \
   --user=$userName

kubectl config use-context ${context}

