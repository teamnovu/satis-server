#!/usr/bin/env bash

# The d
# A simple wrapper for the docker-compose command.
# https://gist.github.com/okaufmann/64c4273287b618270bf4bf9451393b53

projectName=$(basename "$PWD")

dockerComposeFilePath=./dev/docker-compose.yml

# check whether we should run a docker compose command...
# (conflicting commands will be ignored: rm, ps, kill, top, exec, help)
if [[ "$1" =~ ^(build|bundle|config|create|down|events|images|logs|pause|port|pull|push|restart|run|scale|start|stop|unpause|up|version)$ ]]; then
    docker compose -p $projectName -f "$dockerComposeFilePath" "$@"
elif [[ "$1" =~ ^(.rm|.ps|.kill|.top|.exec|.help) ]]; then
    # rewrite conflicting commands to its original one
    firstArg="$1";
    set -- "${firstArg:1}" "${@:2}"
    docker compose -p $projectName -f "$dockerComposeFilePath" "$@"
else
    # ...or forward the command to the container
    containerName=${C:-app}
    docker compose -p $projectName -f "$dockerComposeFilePath" exec $containerName "$@"
fi