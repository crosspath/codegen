# docker

This script generates files for Docker:

1. `Dockerfile` + `.dockerignore` files for production, CI and development environments (based on
   Alpine Linux). You may use them instead of default `Dockerfile` + `.dockerignore` files from
   Rails 7.1+ application generator.
2. File `compose.yaml` for development environment including Redis & Sidekiq.

Also this script respects configuration from `bundle-config` & `yarn` features.

Alpine Linux does not have time zone database, that's why this script adds `tzinfo-data` gem.

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

2. Run shell console within Docker image (placeholders: project-tag, container-id):

```shell
docker run -it project-tag sh
docker exec -it container-id sh
docker exec -it $(docker container ls -alq --filter ancestor=project-tag) sh
```

3. Start service (placeholders: project-tag):

```shell
docker run -d -p 127.0.0.1:3000:3000 project-tag
```

4. Show container IDs of specified image (placeholders: project-tag):

```shell
docker container ls -aq --filter ancestor=project-tag
```

5. Stop service (placeholders: project-tag, container-id):

```shell
docker stop container-id
docker stop $(docker container ls -aq --filter ancestor=project-tag)
```

6. Remove stopped containers (placeholders: project-tag, container-id):

```shell
docker container rm container-id
docker container rm $(docker container ls -aq --filter ancestor=project-tag)
```

7. Easy way to start container if it does not repond to HTTP requests when using commands above (placeholders: project-tag):

```shell
docker run -d --network host project-tag
```

8. Start with `docker compose` feature:

```shell
alias compose-project="docker compose --project-directory . -f .build/compose.yaml"
compose-project pull && compose-project build && compose-project up -d
```

9. Stop with `docker compose` feature (see point 8):

```shell
compose-project down
```
