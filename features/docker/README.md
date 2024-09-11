# docker

This script generates files for Docker:

1. `Dockerfile` + `.dockerignore` files for production, CI and development environments (based on
   Alpine Linux). You may use them instead of default `Dockerfile` + `.dockerignore` files from
   Rails 7.1+ application generator.
2. File `compose.yaml` for development environment including Redis & Sidekiq.
3. Script `bin/docker-dev` for application in Docker running in development environment.
   It installs gems & front-end packages required for your application. You may think of it as
   an addition to standard script `bin/setup`.

Also this script respects configuration from `bundle-config`, `tools` & `yarn` features.

No special actions required from other developers or PCs.

## Cheat-sheet for Docker (example commands)

> Note: prepend every "docker" command with "sudo" if your current user is not included into
> "docker" group.

1. Build Docker image (placeholders: project-tag):

```shell
docker build -t project-tag -f .build/Dockerfile-CI .
docker build -t project-tag -f .build/Dockerfile-development .
docker build -t project-tag -f .build/Dockerfile-production .
```

> File `.build/Dockerfile-CI` uses `.build/Dockerfile-CI.dockerignore` file, and so on.

2. Create and run container from image (placeholders: project-tag, container-id):

* Run shell console (create container)

```shell
docker run -it project-tag sh
```

* Run shell console (attach to existing container)

```shell
docker exec -it container-id sh
docker exec -it $(docker container ls -alq --filter ancestor=project-tag) sh
```

* Start service in background (create container)

```shell
docker run -d -p 127.0.0.1:3000:3000 project-tag
```

* Start service in background (start existing container) when it has "exited" ("stopped") status

```shell
docker start container-id
```

* Start service & attach to it (start existing container) when it has "exited" ("stopped") status

```shell
docker start -ai container-id
```

* Easy way to start container if it does not repond to HTTP requests with "-p" argument

```shell
docker run -d --network host project-tag
```

3. Show container IDs of specified image (placeholders: project-tag):

```shell
docker container ls -aq --filter ancestor=project-tag
```

4. Attach to running container (placeholders: container-id):

```shell
docker attach container-id
```

5. Stop & remove containers (placeholders: project-tag, container-id):

* Stop container

```shell
docker stop container-id
docker stop $(docker container ls -aq --filter ancestor=project-tag)
```

* Remove stopped container

```shell
docker container rm container-id
docker container rm $(docker container ls -aq --filter ancestor=project-tag)
```

6. Usage of `docker compose` feature:

* Start containers

```shell
alias compose-project="docker compose --project-directory . -f .build/compose.yaml"
compose-project pull && compose-project build && compose-project up -d
```

* Stop containers

```shell
compose-project down
```

7. For `Dockerfile-dev` (placeholders: project-tag, container-id, /project/directory):

* Start container and install gems & front-end packages, initialize database

```shell
docker run \
  --mount src=/project/directory,dst=/rails,type=bind \
  --mount src=bundler,dst=/usr/local/bundler,type=volume \
  -it project-tag bin/docker-dev
```
