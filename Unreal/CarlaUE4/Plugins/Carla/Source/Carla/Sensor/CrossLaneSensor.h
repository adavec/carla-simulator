// Copyright (c) 2019 Intel Labs.
//
// This work is licensed under the terms of the MIT license.
// For a copy, see <https://opensource.org/licenses/MIT>.

#pragma once

#include "Carla/Sensor/ShaderBasedSensor.h"

#include "Carla/Actor/ActorDefinition.h"

#include "CrossLaneSensor.generated.h"

/// LaneInvasion sensor representation
/// The actual position calculation is done one client side
UCLASS()
class CARLA_API ACrossLaneSensor : public ASensor
{
  GENERATED_BODY()

public:

  static FActorDefinition GetSensorDefinition();

  ACrossLaneSensor(const FObjectInitializer &ObjectInitializer);
};
