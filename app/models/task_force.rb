# frozen_string_literal: true

class TaskForce < ApplicationRecord
  belongs_to :vehicle, touch: true
  belongs_to :hangar_group, touch: true

  # A fleet filtered by hangar group lists a loaner by its parent's groups, and
  # the touch above only reaches the parent.
  after_commit :schedule_loaner_fleet_vehicle_updates

  private def schedule_loaner_fleet_vehicle_updates
    Vehicle.schedule_fleet_vehicle_updates(Vehicle.where(loaner: true, vehicle_id:).ids)
  end
end
