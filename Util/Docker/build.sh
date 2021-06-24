#!/bin/bash

docker build -t syoliveravisto/carla:adavec --build-arg GIT_BRANCH=adavec -f Carla.Dockerfile .
