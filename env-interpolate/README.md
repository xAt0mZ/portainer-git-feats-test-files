# env-interpolate

This folder contains variations of compose definitions that can be deployed with Portainer.

## Content of a test

- A `docker-compose.yaml` file

```yaml
services:
  nats:
    image: nats
    environment:
      - A=${A}
      - B=${B}
      - C=${C}
```

or

```yaml
services:
  nats:
    image: nats
    env_file:
      - .env
    environment:
      - A=${A}
      - B=${B}
      - C=${C}
```

- A `.env` file

```
A=env
B=env
```

and / or a `stack.env` file

```
A=stack.env
B=stack.env
```

## Automation testing

`automate.sh` will run all the combinations in 2 variants

- -no-ui
- -ui

The `-no-ui` variant will only deploy the stack file without specifying anything else.

The `-ui` variant will deploy the stack file and will override `A=ui`.

### What does it mean

For each file we pass the 2 variables `A` and `B` to the compose file through the various env files.

During the `-ui` variant we override the `A` variable, while letting the `B` variable untouched.

This allows to test if the env file and UI variables are properly merged (`A` is overriden ; `B` is untouched)

The `C` variable is never passed and is always inherited from the Portainer container env. See the [Notes](./README.md#notes) below.

### Expected result

- `-no-ui` variant

  - A=env or stack.env
  - B=env or stack.env
  - C=whatever was passed to the Portainer container on startup

- `-ui` variant
  - A=ui
  - B=env or stack.env
  - C=whatever was passed to the Portainer container on startup

## Detecting regression

Requirements:

- `jq`
- a Portainer access token

Use the `automate.sh` script to deploy all the subfolders automatically.

Extract the environments of the created containers with `extract.sh`.

Once extracted, compare against the result produced by the deployment of this suite with the compose binary (Portainer 2.21.5) using `diff.sh`.

This will ensure there is no regression in variable interpolation.

Full example when running a 2.27.0 instance on `localhost:9000` where the local environment has the ID `3`.

```sh
./automate.sh ptr_O/rmZJwYIBTo/B9IV0FFO7kmaRFnEELc7XrPKJ44BpU= localhost:9000 3
./extract.sh ptr_O/rmZJwYIBTo/B9IV0FFO7kmaRFnEELc7XrPKJ44BpU= localhost:9000 3 > 2.27.0
./diff.sh 2.27.0 output/CE-2.21.5.json
```

If there are no diffs, the `diff.sh` script will display

```json
[]
```

If there are differences the script will display an array of

```json
{
  "Name": "without-ref-in-file-from-stack-env-ui-unpacker",
  "2.27.0": ["A=ui", "B=", "C="],
  "output/CE-2.21.5": ["A=ui", "B=", "C=portainer-container-env"],
  "Diff": {
    "2.27.0": ["C="],
    "output/CE-2.21.5": ["C=portainer-container-env"]
  }
}
```

## Notes

The `C` env var is never set in the various env files under `env-interpolate`. It can be used to ensure the Portainer env is automatically passed (or not) when deploying stacks.

To validate the expected value of `C` you can use

```sh
docker container inspect PORTAINER | jq .[0].Config.Env
```

For example some users are deploying Portainer like so

```
My Portainer compose.yaml contains these lines:

environment:
  - USERNAME=jason

Which allows all of my Portainer-created stacks to reference thusly:

volumes:
  - /home/${USERNAME}/docker/graylog/data:/usr/share/graylog/data
```

or

```
docker run -d -p 9000:9000 \
    --name portainer --restart=always \
    --env-file "/home/user/docker/portainer/docker.env" \
    ...
    portainer/portainer-ce:alpine


then any variable of docker.env could be used when deploying stacks.
```

In 2.21.5 it was possible to use the entire Portainer environment when deploying stack files, as we were using the compose binary from inside the Portainer container. However starting from 2.24.0 (when we removed the compose binary and used the compose lib instead) this is not possible anymore.
