# frozen_string_literal: true

# == Schema Information
#
# Table name: task_forces
#
#  id              :uuid             not null, primary key
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  hangar_group_id :uuid
#  vehicle_id      :uuid
#
# Indexes
#
#  index_task_forces_on_hangar_group_id  (hangar_group_id)
#  index_task_forces_on_vehicle_id       (vehicle_id)
#
class TaskForce < ApplicationRecord
  belongs_to :vehicle, touch: true
  belongs_to :hangar_group, touch: true

  after_commit :schedule_fleet_vehicle_update

  def schedule_fleet_vehicle_update
    Updater::FleetVehicleUpdateJob.perform_async(vehicle_id)
  end
end
