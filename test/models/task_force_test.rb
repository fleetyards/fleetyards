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
require 'test_helper'

class TaskForceTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  should belong_to(:vehicle)
  should belong_to(:hangar_group)

  let(:raven) { vehicles :raven }
  let(:hangargroup) { hangar_groups :hangargroupone }

  describe '#schedule_fleet_vehicle_update' do
    it 'enqueues update job on task_force create' do
      assert_enqueued_with(job: Updater::FleetVehicleUpdateJob) do
        TaskForce.create(vehicle_id: raven.id, hangar_group_id: hangargroup.id)
      end
    end

    it 'enqueues update job on task_force destroy' do
      taskforce = TaskForce.create(vehicle_id: raven.id, hangar_group_id: hangargroup.id)

      assert_enqueued_with(job: Updater::FleetVehicleUpdateJob) do
        taskforce.destroy
      end
    end
  end
end
