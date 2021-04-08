# NGINX Plus API Gateway - keyval zone based

## Description

This version relies on NGINX keyval zones for configuration. Keyval zones can be fully managed through REST APIs

## Current and upcoming features

- [X] per-URI OIDC IdP selection (endpoints, client id, client key) based on NGINX "keyval_zone"
- [X] per-URI/per-REST API function HTTP method filtering
- [X] per-REST API function quota
- [X] URI rewriting support

## How to deploy

### Configure IdPs

On the IdP side a client must be configured, with the appropriate redirect URIs:

- testapi-1 IdP - redirect_uri: http://api.ff.lan:80/testapi-1/*
- testapi-2 IdP - redirect_uri: http://api.ff.lan:80/testapi-2/*


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
cd manifests-keyval
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

- NGINX-to-upstreams configuration: the "upstream" section must point to API services 
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

- OIDC keyval zones setup
```
kubectl apply -f 6.openid_connect_configuration.conf.yaml
```

- Deploy the NGINX Plus API Gateway instance
```
kubectl apply -f 7.nginx-apigw.yaml
```

- Populate required keyval_zones through NGINX REST API

- AuthZ endpoints

```
curl -i -X POST -H "Host: api" http://api.ff.lan/api/6/http/keyvals/oidc_authz_endpoints -d '{"/testapi-1/":"https://sso.ff.lan/auth/realms/master/protocol/openid-connect/auth"}'
curl -i -X POST -H "Host: api" http://api.ff.lan/api/6/http/keyvals/oidc_authz_endpoints -d '{"/testapi-2/":"https://sso.ff.lan/auth/realms/master/protocol/openid-connect/auth"}'
```

- Token endpoints

```
curl -i -X POST -H "Host: api" http://api.ff.lan/api/6/http/keyvals/oidc_token_endpoints -d '{"/testapi-1/":"https://sso.ff.lan/auth/realms/master/protocol/openid-connect/token"}'
curl -i -X POST -H "Host: api" http://api.ff.lan/api/6/http/keyvals/oidc_token_endpoints -d '{"/testapi-2/":"https://sso.ff.lan/auth/realms/master/protocol/openid-connect/token"}'
```

- JWT key endpoints

```
curl -i -X POST -H "Host: api" http://api.ff.lan/api/6/http/keyvals/oidc_jwt_keyfiles -d '{"/testapi-1/":"https://sso.ff.lan/auth/realms/master/protocol/openid-connect/certs"}'
curl -i -X POST -H "Host: api" http://api.ff.lan/api/6/http/keyvals/oidc_jwt_keyfiles -d '{"/testapi-2/":"https://sso.ff.lan/auth/realms/master/protocol/openid-connect/certs"}'
```

- OIDC client IDs

```
curl -i -X POST -H "Host: api" http://api.ff.lan/api/6/http/keyvals/oidc_clients -d '{"/testapi-1/":"[THIS_API_OIDC_CLIENT_ID]"}'
curl -i -X POST -H "Host: api" http://api.ff.lan/api/6/http/keyvals/oidc_clients -d '{"/testapi-2/":"[THIS_API_OIDC_CLIENT_ID]"}'
```

- OIDC client secrets

```
curl -i -X POST -H "Host: api" http://api.ff.lan/api/6/http/keyvals/oidc_client_secrets -d '{"/testapi-1/":"[OIDC CLIENT SECRET_GOES_HERE]"}'
curl -i -X POST -H "Host: api" http://api.ff.lan/api/6/http/keyvals/oidc_client_secrets -d '{"/testapi-2/":"[OIDC_CLIENT_SECRET_GOES_HERE]"}'
```

- Per-NGINX Plus Unique HMAC

```
curl -i -X POST -H "Host: api" http://api.ff.lan/api/6/http/keyvals/oidc_hmacs -d '{"/":"[PER_NGINX_CLUSTER_UNIQUE_HMAC]"}'
```

- Logout URIs

```
curl -i -X POST -H "Host: api" http://api.ff.lan/api/6/http/keyvals/oidc_logout_redirect -d '{"/testapi-1/":"[THIS_API_LOGOUT_URI]"}'
curl -i -X POST -H "Host: api" http://api.ff.lan/api/6/http/keyvals/oidc_logout_redirect -d '{"/testapi-2/":"[THIS_API_LOGOUT_URI]"}'
```

- Allowed HTTP methods (if not defined, all methods are allowed)

```
curl -i -X POST -H "Host: api" http://api.ff.lan/api/6/http/keyvals/allowed_http_methods -d '{"/testapi-1/":"GET"}'
curl -i -X POST -H "Host: api" http://api.ff.lan/api/6/http/keyvals/allowed_http_methods -d '{"/testapi-2/":"GET POST"}'
```

- REST API quotas: quotas must be enabled (set to 1) per URI-token, then per-Consumer quota shall be set (in the example: Consumer 'foo' can call 5 times the /testapi-1/tasks service)

```
curl -i -X POST -H "Host: api" -d '{"/testapi-1/":"1"}' http://api.ff.lan/api/6/http/keyvals/quotas_enabled
curl -i -X POST -H "Host: api" -d '{"foo:/testapi-1/tasks":5}' http://api.ff.lan/api/6/http/keyvals/quotas
```

- URI rewriting: client requests for /testapi-1/tasks-external are rewritten to /testapi-1/tasks towards the backend

```
curl -i -X POST -H "Host: api" http://api.ff.lan/api/6/http/keyvals/uri_rewrite -d '{"/testapi-1/tasks-external":"/testapi-1/tasks"}'
```

- URI rewriting: client requests for /testapi-1/tasks-external are rewritten to another 3rd party endpoint

```
curl -i -X POST -H "Host: api" http://api.ff.lan/api/6/http/keyvals/uri_rewrite -d '{"/testapi-1/tasks-external":"https://new-fqdn.com/api/service"}'
```

### Test!

```
curl -i -X GET http://api.ff.lan/testapi-1/tasks
curl -i -X GET http://api.ff.lan/testapi-2/tasks
curl -i -X GET -H "Consumer: foo" http://api.ff.lan/testapi-1/tasks
```
