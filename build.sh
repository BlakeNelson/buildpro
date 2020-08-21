#!/usr/bin/env bash
docker container run \
  --volume $(pwd)/image/scripts:/scripts \
  --volume $1:/srcdir \
  --user $(id -u ${USER}):$(id -g ${USER}) \
  --rm -it --name build_buildpro buildpro:v1 \
  build
