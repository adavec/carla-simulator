FROM syoliveravisto/carla-prerequisites:latest

ARG GIT_BRANCH

USER ue4

RUN cd /home/ue4 && \
  if [ -z ${GIT_BRANCH+x} ]; then git clone --depth 1 https://github.com/adavec/carla-simulator.git; \
  else git clone --depth 1 --branch $GIT_BRANCH https://github.com/adavec/carla-simulator.git; fi && \
  cd /home/ue4/carla-simulator && \
  ./Update.sh

RUN cd /home/ue4/carla-simulator && \
  make CarlaUE4Editor
  
RUN cd /home/ue4/carla-simulator && \
  make PythonAPI
  
RUN cd /home/ue4/carla-simulator && \
  make build.utils
  
RUN cd /home/ue4/carla-simulator && \
  make package

RUN cd /home/ue4/carla-simulator && \
  rm -r /home/ue4/carla/Dist

WORKDIR /home/ue4/carla
