# Docker satis-server

For more details about satis-server image consult the upstream repo at https://github.com/lukaszlach/satis-server.

## Dev

`d` is a little helper script to run docker compose commands with typing less and having the docker-compose.yml in a subfolder.

'''
./d build --pull --build-arg WEBHOOK_VERSION=2.8.0 --build-arg SATIS_SERVER_VERSION=dev-main --progress=plain && ./d up -d --force-recreate --remove-orphans && ./d logs -f
```

Now you can access the satis-server at http://localhost:9100