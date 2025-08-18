#!/usr/bin/env bash

# Clean the test resources from the environment

usage="Usage: $0 API_TOKEN PORTAINER_HOST ENDPOINT_ID"

token=${1?$usage}
shift
host=${1?$usage}
shift
endpointID=${1?$usage}
shift

stacks_url="${host}/api/stacks?filters=%7B%22EndpointID%22:$endpointID,%22IncludeOrphanedStacks%22:false%7D"
delete_url="${host}/api/stacks"

curl -s -H "x-api-key: $token" "$stacks_url" |
  jq '.[] | select(.Name | startswith("with")) | .Id' |
  xargs -I % curl -H "x-api-key: $token" -X DELETE "$delete_url/%?endpointId=$endpointID"
