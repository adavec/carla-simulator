#!/bin/bash

cd ../..
docker build -t syoliveravisto/carla-build:adavec-0.9.11 --build-arg GIT_BRANCH=adavec-0.9.11 -f Util/Docker/Carla.Dockerfile .
