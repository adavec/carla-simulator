// Copyright (c) 2019 Computer Vision Center (CVC) at the Universitat Autonoma
// de Barcelona (UAB).
//
// This work is licensed under the terms of the MIT license.
// For a copy, see <https://opensource.org/licenses/MIT>.

#include "carla/client/CrossLaneSensor.h"

#include "carla/Logging.h"
#include "carla/client/Map.h"
#include "carla/client/Vehicle.h"
#include "carla/client/detail/Simulator.h"
#include "carla/geom/Location.h"
#include "carla/geom/Math.h"
#include "carla/sensor/data/CrossLaneEvent.h"
#include "carla/road/Lane.h"

#include <exception>
#include <fstream>

namespace carla {
namespace client {

  // ===========================================================================
  // -- Static local methods ---------------------------------------------------
  // ===========================================================================

  static geom::Location Rotate(float yaw, const geom::Location &location) {
    yaw *= geom::Math::Pi<float>() / 180.0f;
    const float c = std::cos(yaw);
    const float s = std::sin(yaw);
    return {
        c * location.x - s * location.y,
        s * location.x + c * location.y,
        location.z};
  }

  // ===========================================================================
  // -- CrossLaneCallback ---------------------------------------------------
  // ===========================================================================

  class CrossLaneCallback {
  public:

    CrossLaneCallback(
        const Vehicle &vehicle,
        SharedPtr<Map> &&map,
        Sensor::CallbackFunctionType &&user_callback)
      : _parent(vehicle.GetId()),
        _parent_bounding_box(vehicle.GetBoundingBox()),
        _map(std::move(map)),
        _callback(std::move(user_callback)),
        _state(sensor::data::CrossLaneState::None) {
      DEBUG_ASSERT(_map != nullptr);
    }

    void Tick(const WorldSnapshot &snapshot) const;

  private:

    struct Bounds {
      size_t frame;
      std::array<geom::Location, 4u> left_corners;
      std::array<geom::Location, 4u> right_corners;
    };

    std::shared_ptr<const Bounds> MakeBounds(
        size_t frame,
        const geom::Transform &vehicle_transform) const;

    ActorId _parent;

    geom::BoundingBox _parent_bounding_box;

    SharedPtr<const Map> _map;

    Sensor::CallbackFunctionType _callback;

    mutable AtomicSharedPtr<const Bounds> _bounds;
    mutable sensor::data::CrossLaneState _state;
  };

  void CrossLaneCallback::Tick(const WorldSnapshot &snapshot) const {
    // Make sure the parent is alive.
    auto parent = snapshot.Find(_parent);
    if (!parent) {
      return;
    }

    auto next = MakeBounds(snapshot.GetFrame(), parent->transform);
    auto prev = _bounds.load();

    // First frame it'll be null.
    if ((prev == nullptr) && _bounds.compare_exchange(&prev, next)) {
      return;
    }

    // Make sure the distance is long enough.
    constexpr float distance_threshold = 10.0f * std::numeric_limits<float>::epsilon();
    for (auto i = 0u; i < 4u; ++i) {
      if ((next->left_corners[i] - prev->left_corners[i]).Length() < distance_threshold) {
        return;
      }
      if ((next->right_corners[i] - prev->right_corners[i]).Length() < distance_threshold) {
        return;
      }
    }

    // Make sure the current frame is up-to-date.
    do {
      if (prev->frame >= next->frame) {
        return;
      }
    } while (!_bounds.compare_exchange(&prev, next));


    // Finally it's safe to compute the crossed lanes.
    std::vector<road::element::LaneMarking> left_crossed_lanes;
    std::vector<road::element::LaneMarking> right_crossed_lanes;
    for (auto i = 0u; i < 3u; ++i) {
      const auto left_lanes = _map->CalculateCrossedLanes(next->left_corners[i], next->left_corners[i+1]);
      left_crossed_lanes.insert(left_crossed_lanes.end(), left_lanes.begin(), left_lanes.end());
      const auto right_lanes = _map->CalculateCrossedLanes(next->right_corners[i], next->right_corners[i+1]);
      right_crossed_lanes.insert(right_crossed_lanes.end(), right_lanes.begin(), right_lanes.end());
    }

    std::vector<road::element::LaneMarking> crossed_lanes;
    sensor::data::CrossLaneState state = sensor::data::CrossLaneState::None;
    if (!left_crossed_lanes.empty() || !right_crossed_lanes.empty()) {

      if (!left_crossed_lanes.empty() && right_crossed_lanes.empty()) {
        crossed_lanes = std::move(left_crossed_lanes);
        state = sensor::data::CrossLaneState::Left;
      }
      else if (left_crossed_lanes.empty() && !right_crossed_lanes.empty()) {
        crossed_lanes = std::move(right_crossed_lanes);
        state = sensor::data::CrossLaneState::Right;
      }
      else
      {

        static constexpr uint32_t FLAGS =
            static_cast<uint32_t>(road::Lane::LaneType::Driving) |
            static_cast<uint32_t>(road::Lane::LaneType::Bidirectional) |
            static_cast<uint32_t>(road::Lane::LaneType::Biking) |
            static_cast<uint32_t>(road::Lane::LaneType::Parking);

        const auto& road_map = _map->GetMap();
        const auto w0 = road_map.GetClosestWaypointOnRoad(parent->transform.location, FLAGS);
        const auto transform = road_map.ComputeTransform(*w0);
        const auto current_waypoint_direction = transform.GetForwardVector();
        const auto car_direction = parent->transform.GetForwardVector();

        // cross product
        const auto cross_is_at_left =
            (-current_waypoint_direction.x * car_direction.y + current_waypoint_direction.y * car_direction.x) < 0;

        // dot product
        const auto car_is_reverse =
          (current_waypoint_direction.x * car_direction.x + current_waypoint_direction.y * car_direction.y) < 0;

        if (!car_is_reverse && !cross_is_at_left || car_is_reverse && cross_is_at_left) {
          crossed_lanes = std::move(left_crossed_lanes);
          state = sensor::data::CrossLaneState::Left;
        }
        else
        {
          crossed_lanes = std::move(right_crossed_lanes);
          state = sensor::data::CrossLaneState::Right;
        }
      }
    }

    if (state != _state) {
      _state = state;
      _callback(MakeShared<sensor::data::CrossLaneEvent>(
          snapshot.GetTimestamp().frame,
          snapshot.GetTimestamp().elapsed_seconds,
          parent->transform,
          _parent,
          state,
          std::move(crossed_lanes)));
    }

  }

  std::shared_ptr<const CrossLaneCallback::Bounds> CrossLaneCallback::MakeBounds(
      const size_t frame,
      const geom::Transform &transform) const {
    const auto &box = _parent_bounding_box;
    const auto location = transform.location + box.location;
    const auto yaw = transform.rotation.yaw;
    return std::make_shared<Bounds>(
      Bounds{
        frame,
        {
          location + Rotate(yaw, geom::Location( box.extent.x,          0.0f, 0.0f)),
          location + Rotate(yaw, geom::Location( box.extent.x, -box.extent.y, 0.0f)),
          location + Rotate(yaw, geom::Location(-box.extent.x, -box.extent.y, 0.0f)),
          location + Rotate(yaw, geom::Location(-box.extent.x,          0.0f, 0.0f))
        },
        {
          location + Rotate(yaw, geom::Location( box.extent.x,          0.0f, 0.0f)),
          location + Rotate(yaw, geom::Location( box.extent.x,  box.extent.y, 0.0f)),
          location + Rotate(yaw, geom::Location(-box.extent.x,  box.extent.y, 0.0f)),
          location + Rotate(yaw, geom::Location(-box.extent.x,          0.0f, 0.0f))
        },
      }
    );
  }

  // ===========================================================================
  // -- CrossLaneSensor -----------------------------------------------------
  // ===========================================================================

  CrossLaneSensor::~CrossLaneSensor() {
    Stop();
  }

  void CrossLaneSensor::Listen(CallbackFunctionType callback) {
    auto vehicle = boost::dynamic_pointer_cast<Vehicle>(GetParent());
    if (vehicle == nullptr) {
      log_error(GetDisplayId(), ": not attached to a vehicle");
      return;
    }

    auto episode = GetEpisode().Lock();
    
    auto cb = std::make_shared<CrossLaneCallback>(
        *vehicle,
        episode->GetCurrentMap(),
        std::move(callback));

    const size_t callback_id = episode->RegisterOnTickEvent([cb=std::move(cb)](const auto &snapshot) {
      try {
        cb->Tick(snapshot);
      } catch (const std::exception &e) {
        log_error("CrossLaneSensor:", e.what());
      }
    });

    const size_t previous = _callback_id.exchange(callback_id);
    if (previous != 0u) {
      episode->RemoveOnTickEvent(previous);
    }
  }

  void CrossLaneSensor::Stop() {
    const size_t previous = _callback_id.exchange(0u);
    auto episode = GetEpisode().TryLock();
    if ((previous != 0u) && (episode != nullptr)) {
      episode->RemoveOnTickEvent(previous);
    }
  }

} // namespace client
} // namespace carla
