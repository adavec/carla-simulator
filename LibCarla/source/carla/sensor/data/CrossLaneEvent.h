// Copyright (c) 2017 Computer Vision Center (CVC) at the Universitat Autonoma
// de Barcelona (UAB).
//
// This work is licensed under the terms of the MIT license.
// For a copy, see <https://opensource.org/licenses/MIT>.

#pragma once

#include "carla/sensor/SensorData.h"

#include "carla/client/Actor.h"
#include "carla/road/element/LaneMarking.h"
#include "carla/rpc/ActorId.h"

#include <vector>

namespace carla {
namespace sensor {
namespace data {

  enum class CrossLaneState
  {
    None,
    Left,
    Right
  };
  
  /// A change of lane event.
  class CrossLaneEvent : public SensorData {
  public:

    using LaneMarking = road::element::LaneMarking;

    explicit CrossLaneEvent(
        size_t frame,
        double timestamp,
        const rpc::Transform &sensor_transform,
        ActorId parent,
        CrossLaneState state,
        std::vector<LaneMarking> crossed_lane_markings)
      : SensorData(frame, timestamp, sensor_transform),
        _parent(parent),
        _crossed_lane_markings(state, std::move(crossed_lane_markings)) {}

    /// Get "self" actor. Actor that invaded another lane.
    SharedPtr<client::Actor> GetActor() const;

    /// List of lane markings that have been crossed.
    const std::pair<CrossLaneState, std::vector<LaneMarking>> &GetCrossedLaneMarkings() const {
      return _crossed_lane_markings;
    }

  private:

    ActorId _parent;

    std::pair<CrossLaneState, std::vector<LaneMarking>> _crossed_lane_markings;
  };

} // namespace data
} // namespace sensor
} // namespace carla
