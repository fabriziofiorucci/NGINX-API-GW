# NGINX Plus API Gateway - Advanced OIDC setup

## Description

The code here is based on https://docs.nginx.com/nginx/deployment-guides/single-sign-on/

The original deployment guide focuses on FQDN-based OIDC IdP selection, this repository provides a number of changes and enhancements to support dynamic multiple IdPs based on the URI, authorization and rewriting.

This supports deployments where all published REST APIs share a common FQDN (ie. http(s)://api.ff.lan/) and must be handled based on the first URI token, that is:

```
http://api.ff.lan/testapi-1/getCustomer -> this gets authenticated by IdP #1
http://api.ff.lan/testapi-2/getCustomer -> this gets authenticated by IdP #2
```

## Current and upcoming features

- [X] per-URI OIDC IdP selection (endpoints, client id, client key) based on NGINX "maps"

- [ ] URI rewriting support
- [ ] per-REST API function HTTP method filtering/ACL
- [ ] per-URI OIDC IdP selection (endpoints, client id, client key) based on NGINX "keyval_zone"
- [ ] per-URI OIDC IdP selection (endpoints, client id, client key) based on external keyval backend


## How to deploy

### Configure IdPs

On the IdP side a client must be configured, with the appropriate redirect URIs:

- testapi-1 IdP - redirect_uri: http://api.ff.lan:80/testapi-1/*
- client-2 - redirect_uri: http://api.ff.lan:80/testapi-2/*


### Build and deploy up the first test api

```
#
# testapi-1
# 
# Sample service:
# curl -s -X GET http://api.k8s.ff.lan/testapi-1/tasks | jq
#
# {"tasks":[{"description":"Milk, Cheese, Pizza, Fruit, Tylenol","done":false,"id":1,"title":"Buy groceries"},{"description":"Need to find a good Python tutorial on the web","done":false,"id":2,"title":"Learn Python"}]}
#
cd testapi-1
./build.sh
```

### Build and deploy up the second test api

```
#
# testapi-2
#
# Sample service:
# curl -s -X GET http://api.k8s.ff.lan/testapi-2/tasks | jq
#
# {"tasks":[{"description":"One, Two, Three, Four","done":false,"id":1,"title":"Test API"},{"description":"Lorem Ipsum","done":false,"id":2,"title":"Second task"}]}
#
cd testapi-2
./build.sh
```

### Perform a full cleanup

By default this repo creates a "nginx-apigw" namespace where everything is deployed.

- Move to the manifest dir
```
cd manifests
```

- Perform a full cleanup
```
kubectl delete -f .
```

### Start the two test APIs

- Namespace creation
```
kubectl apply -f 0.ns.yaml
```

- Sample APIs startup
```
kubectl apply -f 1.sample_apis.yaml
```

### Create NGINX ConfigMaps

- nginx.conf
```
kubectl apply -f 2.nginx.conf.yaml 
```

- NGINX-to-upstreams configuration
```
kubectl apply -f 3.frontend.conf.yaml
```

- Javascript OIDC code
```
kubectl apply -f 4.openid_connect.js.yaml
```

- Internal OIDC locations: the "resolver" line must be changed for DNS lookup of IdP endpoint
```
kubectl apply -f 5.openid_connect.server_conf.yaml
```

- Configure keyval maps in 6.openid_connect_configuration.conf.yaml and then apply it
```
kubectl apply -f 6.openid_connect_configuration.conf.yaml
```

- Deploy the NGINX Plus API Gateway instance
```
kubectl apply -f 7.nginx-apigw.yaml
```

### Test!

```
curl -i -X GET http://api.ff.lan/testapi-1/tasks
curl -i -X GET http://api.ff.lan/testapi-2/tasks
```
