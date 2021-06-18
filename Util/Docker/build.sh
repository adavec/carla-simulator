#!/bin/bash

docker build -t syoliveravisto/carla:adavec --no-cache --build-arg GIT_BRANCH=adavec -f Carla.Dockerfile .
