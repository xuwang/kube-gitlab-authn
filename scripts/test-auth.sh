#!/bin/bash

# test the kube-gitlab-authn server:
#  docker run -it --rm -e GITLAB_API_ENDPOINT=${GITLAB_API_ENDPOINT} -p 3000:3000 xuwang/kube-gitlab-authn
#
# see https://kubernetes.io/docs/admin/authentication/#webhook-token-authentication

GITLAB_TOKEN=${GITLAB_TOKEN:-my_private_token}

read -r -d '' DATA <<EOF
{
  "apiVersion": "authentication.k8s.io/v1beta1",
  "kind": "TokenReview",
  "spec": {
    "token": "${GITLAB_TOKEN}"
  }
}
EOF

curl -H "Content-Type: application/json" -X POST -d "${DATA}" http://localhost:3000/authenticate