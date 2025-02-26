#!/bin/bash

usage="Usage: $0 API_TOKEN PORTAINER_HOST endpointID"

token=${1?$usage}
shift
host=${1?$usage}
shift
endpointID=${1?$usage}
shift

url="${host}/api/stacks/create/standalone/repository?endpointId=$endpointID"

declare -a roots=("with-ref-in-file" "without-ref-in-file")
declare -a dirs=("from-env" "from-stack-env" "from-env-and-stack-env")
declare -a variants=("no-ui" "ui")

function test() {
  local root=$1
  local dir=$2
  local variant=$3

  local name="${root}-${dir}-${variant}"
  local env='[]'
  if [[ "$variant" == "ui" ]]; then
    env='[{"name":"A","value":"ui","needsDeletion":false}]'
  fi
  local path="env-interpolate/$root/$dir/docker-compose.yaml"

  local payload=$(
    jq -n \
      --arg name "$name" \
      --arg path "$path" \
      --argjson env "$env" \
      '{
      method:"repository",
      type:"standalone",
      Name: $name,
      RepositoryURL: "https://github.com/xat0mz/portainer-git-feats-test-files",
      RepositoryReferenceName: "refs/heads/master",
      ComposeFile: $path,
      AdditionalFiles: [],
      RepositoryAuthentication: false,
      RepositoryUsername: "",
      RepositoryPassword: "",
      RepositoryGitCredentialID: 0,
      Env: $env,
      SupportRelativePath: false,
      FilesystemPath: "",
      TLSSkipVerify: false,
      }'
  )

  curl -H "x-api-key: $token" -s --json "$payload" "$url"
}

for root in "${roots[@]}"; do
  for dir in "${dirs[@]}"; do
    for variant in "${variants[@]}"; do
    echo " >> Testing: $root $dir $variant"
    test $root $dir $variant
    echo ""
    done
  done
done
