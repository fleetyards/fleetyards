# frozen_string_literal: true

# == Schema Information
#
# Table name: vehicles
#
#  id                :uuid             not null, primary key
#  alternative_names :string
#  flagship          :boolean          default(FALSE)
#  hidden            :boolean          default(FALSE)
#  loaner            :boolean          default(FALSE)
#  name              :string(255)
#  name_visible      :boolean          default(FALSE)
#  notify            :boolean          default(TRUE)
#  public            :boolean          default(FALSE)
#  purchased         :boolean          default(FALSE)
#  sale_notify       :boolean          default(FALSE)
#  serial            :string
#  slug              :string
#  created_at        :datetime
#  updated_at        :datetime
#  model_id          :uuid
#  model_paint_id    :uuid
#  module_package_id :uuid
#  user_id           :uuid
#  vehicle_id        :uuid
#
# Indexes
#
#  index_vehicles_on_model_id            (model_id)
#  index_vehicles_on_model_id_and_id     (model_id,id)
#  index_vehicles_on_serial_and_user_id  (serial,user_id) UNIQUE
#  index_vehicles_on_user_id             (user_id)
#
require 'test_helper'

class VehicleTest < ActiveSupport::TestCase
  should belong_to(:user)
  should belong_to(:model)
  should belong_to(:model_paint).optional(true)
  should belong_to(:module_package).optional(true)

  let(:raven) { vehicles :raven }
  let(:hangargroup) { hangar_groups :hangargroupone }

  describe '#schedule_fleet_vehicle_update' do
    it 'enqueues update job on purchase change' do
      raven.update(purchased: !raven.purchased)

      assert_equal 1, Updater::FleetVehicleUpdateJob.jobs.size
    end

    it 'does not enqueues update job if vehicle is hidden' do
      raven.update(hidden: true)

      raven.update(purchased: !raven.purchased)

      assert_equal 0, Updater::FleetVehicleUpdateJob.jobs.size
    end
  end
end
