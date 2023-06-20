# Docker satis-server

For more details about satis-server image consult the upstream repo at https://github.com/lukaszlach/satis-server.

## Why this Fork?

This fork is a extended version of satis-server with a custom auth mechanism for our company. It is not intended to be used by others.

## Configuration

You can define local users in the `users.json` file. The file should be mounted into the container at `/etc/satis-server/users.json`.

The `users.json` file has the following format:

```json
{
    "user1": "password1",
    "user2": "password2",
    "user3": "password3"
}
```

## Dev

`d` is a little helper script to run docker compose commands with typing less and having the docker-compose.yml in a subfolder.

```bash
./d build --pull --build-arg WEBHOOK_VERSION=2.8.0 --build-arg SATIS_SERVER_VERSION=dev-main --progress=plain && ./d up -d --force-recreate --remove-orphans && ./d logs -f
```

Now you can access the satis-server at http://localhost:9100