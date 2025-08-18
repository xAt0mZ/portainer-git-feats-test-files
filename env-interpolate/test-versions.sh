#!/usr/bin/env bash

# Automate the generation of output for all versions

usage="Usage: $0 license version [versions...]"

license=${1?$usage}
if [[ ! $license == 3-* ]]; then
  echo "$usage"
  exit 1
fi
shift

if [[ "$#" -lt 1 ]]; then
  echo "$usage"
  exit 1
fi

declare -a editions=("ce" "ee")

function post() {
  content="$1"
  token="$2"

  curl --json "$content"
}

url="localhost:9000"

for version in "$@"; do
  for edition in "${editions[@]}"; do
    echo "===== Testing "${edition^^}" $version ====="

    echo "- Creating the portainer container"
    docker rm -f portainer_tmp 2>/dev/null
    docker run -q -d -p 9000:9000 --name portainer_tmp -v /var/run/docker.sock:/var/run/docker.sock -e C="portainer-env" "portainer/portainer-$edition:$version" >/dev/null

    echo "Waiting for the container to be online..."
    while [[ true ]]; do
      sleep 1s
      curl -s -I "$url" >/dev/null
      if [[ "$(echo $?)" == "0" ]]; then
        break
      fi
    done

    echo "- Creating admin"
    # POST http://localhost:9000/api/users/admin/init {"Username":"admin","Password":"portainer1234"}
    curl -s --json '{"Username":"admin","Password":"portainer1234"}' "http://$url/api/users/admin/init" >/dev/null

    echo "- Logging in"
    # POST http://localhost:9000/api/auth {"username":"admin","password":"portainer1234"} .jwt
    jwt=$(curl -s --json '{"username":"admin","password":"portainer1234"}' "http://$url/api/auth" | jq -r .jwt)

    if [[ "$edition" == "ee" ]]; then
      echo "- Adding license"
      # POST http://localhost:9000/api/licenses/add?force=true {"key":"3-xxxxxx"}
      curl -s -H "Authorization: Bearer $jwt" --json "{\"key\":\"$license\"}" "http://$url/api/licenses/add?force=true" >/dev/null
    fi

    echo "- Creating local env"
    # POST http://localhost:9000/api/endpoints {"Name": "local", "EndpointCreationType": 1, "URL":"", "PublicURL": "", "TagIds": [], "ContainerEngine":"docker"} - >.id
    endpointId=$(curl -s -H "Authorization: Bearer $jwt" -F Name="local" -F EndpointCreationType=1 -F ContainerEngine="docker" "http://$url/api/endpoints" | jq -r .Id)

    echo "- Creating an API token"
    # POST http://localhost:9000/api/users/1/tokens {"password":"portainer1234","description":"de"} - >.rawAPIKey
    token=$(curl -s -H "Authorization: Bearer $jwt" --json '{"password":"portainer1234","description":"token"}' "http://$url/api/users/1/tokens" | jq -r .rawAPIKey)

    echo "- Starting tests"
    if [[ "$edition" == "ce" ]]; then
      ./test-scripts/1.automate-stack-creation.sh "$token" "$url" "$endpointId" true
    else
      ./test-scripts/1.automate-stack-creation.sh "$token" "$url" "$endpointId"
    fi

    echo "- Extracting data"
    ./test-scripts/2.extract-containers-envs.sh "$token" "$url" "$endpointId" >"./output/${edition^^}-${version}.json"

    echo "- Cleaning test resources"
    ./test-scripts/3.clean-resources.sh "$token" "$url" "$endpointId"

    echo "- Removing the portainer container"
    docker rm -f portainer_tmp >/dev/null
    echo "====="
  done
done
