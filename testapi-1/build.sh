#!/bin/bash

REGISTRY=registry.ff.lan
IMAGENAME=testapi-1

docker build --no-cache -t $REGISTRY/$IMAGENAME .
docker tag $REGISTRY/$IMAGENAME $REGISTRY/$IMAGENAME
docker push $REGISTRY/$IMAGENAME

# Sample call
#
# curl -i -X GET http://api.ff.lan/testapi-1/tasks
#
