#!/bin/bash

usage="Usage: $0 API_TOKEN PORTAINER_HOST endpointID"

token=${1?$usage}
shift
host=${1?$usage}
shift
endpointID=${1?$usage}
shift

containers_url="${host}/api/endpoints/$endpointID/docker/containers/json?all=true&filters%3D%7B%22name%22%3A%20%22%5Ewith%22%7D"
details_url="${host}/api/endpoints/$endpointID/docker/containers"

curl -s -H "x-api-key: $token" "$containers_url" |
  jq '.[] | select(.Names[0] | .[1:-7] | startswith("with")) | .Id' |
  xargs -I % curl -s -H "x-api-key: $token" "$details_url/%/json" |
  jq '
  {
    Name: .Name | .[1:-7],
    Env: .Config.Env | map(select(test("^(A|B|C)="))) | sort_by(if test("^A=") then 0 elif test("^B=") then 1 else 2 end),
  }' | jq -n '[inputs]'
