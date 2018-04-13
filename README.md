# Kubernetes Webhook Token Authenticator for GitLab

kube-gitlab-authn implements GitLab webhook token authenticator using [go-gitlab]( github.com/xanzy/go-gitlab) to allow users to use GitLab Personal Access Token to access Kubernetes cluster. It is based on the work of [kubernetes-github-authn](https://github.com/oursky/kubernetes-github-authn/), please refer to the original [README](https://github.com/oursky/kubernetes-github-authn/blob/master/README.md) for the GitHub webhook token authenticator's design and implementation.

## Features

* Support user kubernetes cluster authentication using GitLab personal access token
* Map GitLab users to kubenenetes users
* Map GitLab groups to Kubernetes groups
* Support RABC based authorization

## How to use

### Run the authenticator as DaemonSet

* Start the authenticator as DaemonSet on kube-apiserver:

  ```
  kubectl create -f https://raw.githubusercontent.com/xuwang/kube-gitlab-authn/master/manifests/gitlab-authn.yaml
  ```

  Confirm that the authenticator is running:

  ```
  kubectl get pod -l k8s-app=gitlab-authn -n kube-system
  ```

### Or Run the authenticator as a systemd unit

Here is an example of [gitlab-authn systemd unit](systemd/gitlab-authn.service). This service should run on all master nodes, i.e. along side with kubernetes api-servers.

Make sure to set the `GITLAB_API_ENDPOINT` to your gitlab server in the `gitlab-authn.service` file.

### Configure kube-apiserver

For kube-apiserver to verify bearer token with this authenticator, there are two configuration options need to be set:

 * `--authentication-token-webhook-config-file` a kubeconfig file describing how to
  access the remote webhook service.
 * `--authentication-token-webhook-cache-ttl` how long to cache authentication decisions. Defaults to two minutes.

  Check the [example config file](manifests/token-webhook-config.json) and save
  this file in the Kubernetes master. Set the path to this config file with configurion option above.

  For example, lines related to the authentication and authorization for kube-apiserver:

  ```
  ...
  --authorization-mode=RBAC \
  --authentication-token-webhook-config-file=/var/lib/kubernetes/kube-gitlab-authn.json \
  ...
  ```

## Authorization with role-based access control (RBAC)

Kubernetes support multiple [authorization
plugins](https://kubernetes.io/docs/admin/authorization). Please refer the [Kubernetes
documentation](https://kubernetes.io/docs/admin/authorization/rbac/) about configuring kube-apiserver to use RBAC authentication mode.

Assuming you already have an `admin` user with cluster role configured in your kubecfg. With this admin credential, you can assign roles to other users.

* Distribute your cluster's `ca.pem` to users who need to access the cluster. Here is a [extract_kubecfg_cert.sh]( https://gist.github.com/xueshanf/71f188c58553c82bda16f80483e71918) to help you to extract cluster ca cert from kubecfg.

* Assign user `johndoe` admin role to namespace `gitlab`

```
kubectl create namespace gitlab
kubectl create rolebinding johndoe-admin-binding --clusterrole=admin --user=johndoe --namespace=gitlab
```

* Assign user `johndoe` `admin` role to the cluster in all namespaces:

```
kubectl create clusterrolebinding johndoe-admin-binding --clusterrole=admin --user=johndoe
```

## Generate kubecfg for user

User `johndoe` now can generate `kubecfg` file in $HOME/.kube directory using his [GitLab Access Token](https://gitlab.example.come/profile/account). Here is a [generate-kubecfg.sh](scripts/generate-kubecfg.sh) to help to configure `kubecfg`.

## Test

If the token is incorrect or the authenticator is not working:
```
kubectl get pods
error: You must be logged in to the server (the server has asked for the client to provide credentials)
```
If it works, you should get a list of pods in kubernetes cluster.


