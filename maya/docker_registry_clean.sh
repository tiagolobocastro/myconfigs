#!/usr/bin/env bash

set -x


for repo in $(curl -s http://localhost:5000/v2/_catalog | jq -r '.repositories[]'); do
    tags=$(curl -s http://localhost:5000/v2/$repo/tags/list | jq -r '.tags[]')
    for tag in $tags; do
        curl -X DELETE "http://localhost:5000/v2/$repo/manifests/$tag"
    done
done


echo "DONE"

