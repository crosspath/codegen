# docker

This script generates Dockerfile & Docker Compose files:

1. It creates general and lite ("development") versions of `Dockerfile` and `compose.yaml`.
2. Generated Dockerfiles include instructions for installing required system packages,
   `yarn install` (or `bun install`) and `bundle install`.
3. It adds instructions and config values for Redis & Sidekiq.
4. It integrates with `bundle-config` & `yarn` features.
5. It adds correct entries to `.dockerignore` file.

No special actions required from other developers or PCs.

## Additional information

Generated Dockerfile does not require installation of "required" & "important" packages, because
they are included in base image. You may get list of them via these commands:

```sh
aptitude search ~prequired -F"%p"
aptitude search ~pimportant -F"%p"
```

Note:
You may use command `dpkg -S %(which COMMAND)` to get package name that provides this COMMAND. Example:

```sh
$ dpkg -S $(which cut)  # Your input.
coreutils: /usr/bin/cut # Output.
```

## Cheat-sheet for Docker

1. Build Docker image:

    docker build -t project-tag .
    docker build -t project-tag -f Dockerfile.development .
    (Placeholders: project-tag)

2. Run bash console within Docker image:

    docker run -it project-tag bash
    docker exec -it container-id bash
    (Placeholders: project-tag, container-id)

3. Start service:

    docker run -d --cidfile tmp/docker.cid -p 127.0.0.1:3000:3000 project-tag
    (Placeholders: project-tag)

4. Stop service:

    docker kill $(cat tmp/docker.cid); docker container rm $(cat tmp/docker.cid); rm -f tmp/docker.cid

5. Easy way to start container if it does not repond to HTTP requests when using commands above:

    docker run -d --cidfile tmp/docker.cid --network host project-tag

6. Start with `docker compose` feature:

    docker compose pull; docker compose build; docker compose up -d
    docker compose -f compose.development.yaml pull; ...

7. Stop with `docker compose` feature:

    docker compose down
    docker compose -f compose.development.yaml down
