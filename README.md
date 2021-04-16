# NGINX Plus API Gateway

## Description

This code is based on https://docs.nginx.com/nginx/deployment-guides/single-sign-on/

The original deployment guide focuses on FQDN-based OIDC IdP selection, this repository provides a number of changes and enhancements to support dynamic multiple IdPs based on the URI, authorization and rewriting.

This supports deployments where all published REST APIs share a common FQDN (ie. http(s)://api.ff.lan/) and must be handled based on the first URI token, that is:

```
http://api.ff.lan/testapi-1/tasks -> this gets authenticated by IdP #1
http://api.ff.lan/testapi-2/tasks -> this gets authenticated by IdP #2
```

## Prerequisites

- a Kubernetes or Openshift cluster
- a private registry to push the NGINX Plus image and the test api images
- at least one OIDC IdP (like Keycloak, Okta, MS ADFS, etc)
- the NGINX Plus image must be built with support for javascript (nginx-plus-module-njs) and lua (nginx-plus-module-lua)

## Building the NGINX Plus image

```
cd nginx-dockerfile
```

copy your nginx-repo.crt and nginx-repo.key to the local dir

```
docker build --no-cache -t YOUR_PRIVATE_REGISTRY/nginxplus-js-lua:TAG .
docker push YOUR_PRIVATE_REGISTRY/nginxplus-js-lua:TAG
```

## Current and upcoming features

- [X] per-URI OIDC IdP selection (endpoints, client id, client key) based on NGINX "maps"
- [X] per-URI OIDC IdP selection (endpoints, client id, client key) based on NGINX "keyval_zone"
- [X] per-URI/per-REST API function HTTP method filtering
- [X] per-REST API function quota
- [ ] per-REST API CORS Access-Control-Allow-Origin
- [X] URI rewriting support

## Deployment types

- [Based on NGINX maps](manifests-map)
- [Based on NGINX keyval zones and REST APIs](manifests-keyval)
