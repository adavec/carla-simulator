FROM syoliveravisto/carla-prerequisites:latest

ARG GIT_BRANCH

RUN sudo mkdir /Game && sudo chown carla /Game

USER carla

RUN cd /home/carla && \
  if [ -z ${GIT_BRANCH+x} ]; then git clone --depth 1 https://github.com/adavec/carla-simulator.git; \
  else git clone --depth 1 --branch $GIT_BRANCH https://github.com/adavec/carla-simulator.git; fi && \
  cd /home/carla/carla-simulator && \
  ./Update.sh && \
  ln -s /home/carla/carla-simulator/Unreal/CarlaUE4/Content/Carla /Game/Carla

RUN cd /home/carla/carla-simulator && \
  make CarlaUE4Editor
  
RUN cd /home/carla/carla-simulator && \
  make PythonAPI
  
RUN cd /home/carla/carla-simulator && \
  make build.utils

RUN sudo apt-get install vim -y

#RUN mkdir -p /Game/Carla/Static/TrafficSigns \
#	&& ln -s /Game/Carla/Static/TrafficLight /Game/Carla/Static/TrafficSigns/TrafficLight \ 
#	&& ln -s /Game/Carla/Static/TrafficSigns/TrafficLight/Streetlights_01 /Game/Carla/Static/TrafficSigns/Streetlights_01
#RUN RUN sudo ln -s carla-simulator/Unreal/CarlaUE4/Intermediate/Build/Linux/B4D820EA/CarlaUE4/Shipping /Script && sudo chown -h ue4 /Script

RUN rm -rf /home/carla/carla-simulator/Unreal/CarlaUE4/Content/Carla \
	&& git clone --depth 1 --branch 0.9.12 https://bitbucket.org/carla-simulator/carla-content /home/carla/carla-simulator/Unreal/CarlaUE4/Content/Carla

RUN exit 255

RUN cd /home/carla/carla-simulator && \
  make package

RUN cd /home/carla/carla-simulator && \
  rm -r /home/carla/carla/Dist

WORKDIR /home/carla
