#!/bin/bash

REGISTRY=registry.ff.lan
IMAGENAME=testapi-2

docker build --no-cache -t $REGISTRY/$IMAGENAME .
docker tag $REGISTRY/$IMAGENAME $REGISTRY/$IMAGENAME
docker push $REGISTRY/$IMAGENAME

# Sample call
#
# curl -i -X GET http://api.ff.lan/testapi-2/tasks
#
