FROM syoliveravisto/carla-prerequisites:latest

ARG GIT_BRANCH

RUN sudo mkdir /Game && sudo chown ue4 /Game

USER ue4

RUN rm -rf /home/ue4/carla-simulator/Unreal/CarlaUE4/Content/Carla \
  && git clone --depth 1 --branch 0.9.11 https://bitbucket.org/carla-simulator/carla-content /home/ue4/carla-simulator/Unreal/CarlaUE4/Content/Carla

COPY --chown=ue4 . /home/ue4/carla-simulator

# RUN cd /home/ue4 && \
#   if [ -z ${GIT_BRANCH+x} ]; then git clone --depth 1 https://github.com/adavec/carla-simulator.git; \
#   else git clone --depth 1 --branch $GIT_BRANCH https://github.com/adavec/carla-simulator.git; fi && \
#   cd /home/ue4/carla-simulator && \
#   ./Update.sh && \
#   ln -s /home/ue4/carla-simulator/Unreal/CarlaUE4/Content/Carla /Game/Carla

RUN cd /home/ue4/carla-simulator && \
  make CarlaUE4Editor
  
RUN cd /home/ue4/carla-simulator && \
  make LibCarla
  
RUN cd /home/ue4/carla-simulator && \
  make PythonAPI

RUN cd /home/ue4/carla-simulator && \
  make build.utils

RUN sudo apt-get install vim -y

RUN mkdir /home/ue4/release \
      && cd /home/ue4/carla-simulator \
      && /home/ue4/UnrealEngine/Engine/Build/BatchFiles/RunUAT.sh BuildCookRun \
        -project="/home/ue4/carla-simulator/Unreal/CarlaUE4/CarlaUE4.uproject" \
        -nocompileeditor -nop4 -cook -stage -archive -package -iterate \
        -clientconfig=Shipping -ue4exe=UE4Editor \
        -prereqs -targetplatform=Linux -build -utf8output \
        -archivedirectory=/home/ue4/release || true

# 
# RUN git clone --depth 1 --branch 0.9.0 https://bitbucket.org/carla-simulator/carla-content /home/ue4/content_0.9.0
# 
# RUN mkdir -p /Game/Carla/Static/TrafficSigns \
# 	&& ln -s /Game/Carla/Static/TrafficLight /Game/Carla/Static/TrafficSigns/TrafficLight \ 
# 	&& ln -s /Game/Carla/Static/TrafficSigns/TrafficLight/Streetlights_01 /Game/Carla/Static/TrafficSigns/Streetlights_01
# 
# RUN ln -s /Game/Carla/Static /Game/Static
# 
# RUN sudo mkdir /Engine                                                                                                \
#       && sudo chown ue4 /Engine                                                                                       \
#       && ln -s /home/ue4/carla-simulator/Unreal/CarlaUE4/Saved/Cooked/LinuxNoEditor/Engine/Content/Functions /Engine/Functions
#  
# 
# RUN link_materials_0_9_0(){ ln -s /home/ue4/content_0.9.0/Static/GenericMaterials/$1.uasset /Game/Carla/Static/GenericMaterials/$1.uasset; } \
#     && link_particles_0_9_0(){ ln -s /home/ue4/content_0.9.0/Static/Particles/$1.uasset /Game/Carla/Static/Particles/$1.uasset; } \
#     && link_materials_0_9_0 Ground/SimpleRoad/CheapLaneMarking   \
#     && link_materials_0_9_0 Ground/SimpleRoad/CheapRoad          \
#     && link_materials_0_9_0 Ground/SimpleRoad/CheapSideWalkCurb  \
#     && link_materials_0_9_0 Ground/SimpleRoad/CheapSideWalk_00   \
#     && link_materials_0_9_0 Ground/SimpleRoad/CheapSideWalk_01   \
#     && link_materials_0_9_0 Ground/SimpleRoad/CheapSideWalk_03   \
#                                                                                                                                                                                         \
#     && link_materials_0_9_0 WetPavement/WetPavement_Complex_Road_N2             \
#     && link_materials_0_9_0 WetPavement/WetPavement_Complex_Concrete            \
#     && link_materials_0_9_0 Ground/SideWalks/SidewalkN4/WetPavement_SidewalkN4  \
#     && link_materials_0_9_0 LaneMarking/Lanemarking                             \
#                                                                                                                                                                                                                         \
#     && link_materials_0_9_0 Masters/LowComplexity/CheapRoad_v2                                          \
#     && link_materials_0_9_0 Ground/Road/Asphalt/Asphalt_N1_BaseColor                                    \
#     && link_materials_0_9_0 Ground/Road/Asphalt/Asphalt_N1_Normal                                       \
#     && link_materials_0_9_0 Ground/Generic_Concrete_Material/1024/Generic_Concrete_Material_BaseColor   \
#     && link_materials_0_9_0 Ground/SideWalks/SidewalkN4/B/SideWalkN4_B_BaseColor                        \
#     && link_materials_0_9_0 Ground/SideWalks/SidewalkN4/B/SideWalkN4_B_Normal                           \
#     && link_materials_0_9_0 Masters/LowComplexity/CheapLineMarking                                      \
#     && link_materials_0_9_0 Ground/TileRoads_Lanemarking/TileRoad_LaneMarkingSolid_N2_BaseColor         \
#     && link_materials_0_9_0 Ground/TileRoads_Lanemarking/TileRoad_LaneMarkingSolid_Normal               \
#     && link_materials_0_9_0 WetPavement/WetRoadComplexParam                                             \
#     && mkdir /Game/Carla/Static/GenericMaterials/Ground/Generic_Concrete_Material/2048        \
#     && link_materials_0_9_0 Ground/Generic_Concrete_Material/2048/Generic_Concrete_Material_Normal      \
#     && link_materials_0_9_0 Masters/WetPavement_Complex_Master                                          \
#     && link_materials_0_9_0 Ground/Road/Asphalt/Generic_Asphalt_Material_N3_BaseColor                   \
#     && link_materials_0_9_0 Ground/SideWalks/SidewalkN4/A/SideWalkN4_BaseColor                          \
#     && link_materials_0_9_0 Ground/SideWalks/SidewalkN4/A/SideWalkN4_Normal                             \
#     && link_materials_0_9_0 Ground/SideWalks/SidewalkN4/A/SideWalkN4_Roughness                          \
#                                                                                                         \
#     && link_particles_0_9_0 rain/ripples_sheet_HD_n                                                     \
#     && link_materials_0_9_0 Ground/Generic_Concrete_Material/1024/Generic_Concrete_Material_OcclusionRoughnessMetallic  \
#     && link_materials_0_9_0 Ground/Road/Asphalt/Asphalt_N1_OcclusionRoughnessMetallic                   \
#     && link_materials_0_9_0 Ground/Road/Asphalt/Generic_Asphalt_Material_N4_BaseColor                   \
#     && link_materials_0_9_0 Ground/Road/Asphalt/Generic_Asphalt_Material_N3_Normal                      \
#     && link_materials_0_9_0 Ground/Road/Asphalt/Generic_Asphalt_Material_N3_Roughness                   \
#     && link_materials_0_9_0 Ground/Road/Asphalt/Generic_Asphalt_Material_N4_Normal                      \
#     && link_materials_0_9_0 Ground/Road/Asphalt/Generic_Asphalt_Material_N4_Roughness                   \
#                                                                                                         \
#     && link_materials_0_9_0 Ground/Road/Asphalt/TileRoad_Asphalt_N1_BaseColor                           \
#     && link_materials_0_9_0 Ground/Road/Asphalt/TileRoad                                                \
#     && link_materials_0_9_0 Ground/Generic_Concrete_Material/2048/Generic_Concrete_Material_Normal      \
#     && link_materials_0_9_0 Masters/LowComplexity/CheapRoad_v2                                          \
#     && link_materials_0_9_0 Ground/TileRoads_Lanemarking/TileRoad_LaneMarkingSolid_Roughness            \
#     && link_materials_0_9_0 Ground/SideWalks/SidewalkN4/B/SidewalkN4_B_Roughness
# 
# RUN cp Unreal/CarlaUE4/Config/DefaultGame.ini Unreal/CarlaUE4/Config/DefaultGame.ini.old \
#       && sed 's/\+LowRoadMaterials/#&/' Unreal/CarlaUE4/Config/DefaultGame.ini | sed 's/\+EpicRoadMaterials/#&/' > Unreal/CarlaUE4/Config/DefaultGame.ini
# 
# RUN sudo ln -s /home/ue4/carla-simulator/Unreal/CarlaUE4/Intermediate/Build/Linux/B4D820EA/CarlaUE4/Shipping /Script && sudo chown -h ue4 /Script
# 
# RUN sudo ln -s /Game /Gaame && sudo chown -h ue4 /Gaame
# 
# RUN exit 255
# 
# RUN cd /home/ue4/carla-simulator && \
#   make package
# 
# RUN cd /home/ue4/carla-simulator && \
#   rm -r /home/ue4/carla/Dist

WORKDIR /home/ue4/carla-simulator
