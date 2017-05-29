FROM golang:1.8-alpine as builder

ARG repo=github.comu/xuwang/kube-gitlab-authn
RUN apk --update add git
RUN go get ${repo}

FROM alpine:3.5
RUN apk --no-cache --update add ca-certificates
RUN ls -R
COPY --from=builder /go/bin/kube-gitlab-authn /kube-gitlab-authn
CMD ["/kube-gitlab-authn"]
