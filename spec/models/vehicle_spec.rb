# frozen_string_literal: true

# == Schema Information
#
# Table name: vehicles
#
#  id                   :uuid             not null, primary key
#  alternative_names    :string
#  bought_via           :integer          default("pledge_store")
#  flagship             :boolean          default(FALSE)
#  hidden               :boolean          default(FALSE)
#  loaner               :boolean          default(FALSE)
#  name                 :string(255)
#  name_visible         :boolean          default(FALSE)
#  notify               :boolean          default(TRUE)
#  public               :boolean          default(FALSE)
#  rsi_pledge_synced_at :datetime
#  sale_notify          :boolean          default(FALSE)
#  serial               :string
#  slug                 :string
#  wanted               :boolean          default(FALSE)
#  created_at           :datetime
#  updated_at           :datetime
#  model_id             :uuid
#  model_paint_id       :uuid
#  module_package_id    :uuid
#  rsi_pledge_id        :string
#  user_id              :uuid
#  vehicle_id           :uuid
#
# Indexes
#
#  index_vehicles_on_hidden_and_loaner   (hidden,loaner)
#  index_vehicles_on_model_id_and_id     (model_id,id)
#  index_vehicles_on_serial_and_user_id  (serial,user_id) UNIQUE
#  index_vehicles_on_user_id             (user_id)
#
require "rails_helper"

RSpec.describe Vehicle, type: :model do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:model) }
  it { is_expected.to belong_to(:model_paint).optional(true) }
  it { is_expected.to belong_to(:module_package).optional(true) }

  describe "#schedule_fleet_vehicle_update" do
    let(:vehicle) { create(:vehicle) }

    before do
      vehicle
      Sidekiq::Worker.clear_all
    end

    it "enqueues update job on purchase change" do
      vehicle.update!(wanted: !vehicle.wanted)

      expect(Updater::FleetVehicleUpdateJob.jobs.size).to be >= 1
    end

    it "does not enqueue update job if vehicle is hidden" do
      vehicle.update!(hidden: true)
      Sidekiq::Worker.clear_all

      vehicle.update!(wanted: !vehicle.wanted)

      expect(Updater::FleetVehicleUpdateJob.jobs.size).to eq(0)
    end
  end
end
