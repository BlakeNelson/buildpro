#!/usr/bin/env bash
cd "$( dirname "$0" )"
gtag=23.04
tftag="tf2.14"
# build ghcr.io images
for img in tf_centos7-bld
do
  pkg=ghcr.io/bnelson619/buildpro/${img}:${tftag}
  time docker image build \
    --network=host \
    --build-arg BPROTAG=${gtag} \
    --build-arg TFTAG=${tftag} \
    --file ${img}.dockerfile \
    --tag ghcr.io/bnelson619/buildpro/${img}:latest \
    --tag ${pkg} .
  docker push ghcr.io/bnelson619/buildpro/${img}:${tftag}
done
docker image ls
