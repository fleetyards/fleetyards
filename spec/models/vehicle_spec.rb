# frozen_string_literal: true

# == Schema Information
#
# Table name: vehicles
#
#  id                   :uuid             not null, primary key
#  alternative_names    :string
#  bought_via           :integer          default("pledge_store")
#  bundled              :boolean          default(FALSE), not null
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
#  index_vehicles_on_hidden_and_loaner       (hidden,loaner)
#  index_vehicles_on_model_id_and_id         (model_id,id)
#  index_vehicles_on_serial_and_user_id      (serial,user_id) UNIQUE
#  index_vehicles_on_user_id                 (user_id)
#  index_vehicles_on_vehicle_id_and_bundled  (vehicle_id,bundled)
#
require "rails_helper"

RSpec.describe Vehicle, type: :model do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:model) }
  it { is_expected.to belong_to(:model_paint).optional(true) }
  it { is_expected.to belong_to(:module_package).optional(true) }

  describe "bundled snub crafts" do
    let(:user) { create(:user) }
    let(:snub_model) { create(:model) }
    let(:parent_model) do
      create(:model).tap do |model|
        model.snub_crafts << snub_model
      end
    end

    it "auto-creates a bundled child for each model.snub_crafts entry" do
      expect {
        create(:vehicle, user: user, model: parent_model, wanted: false)
      }.to change { Vehicle.where(bundled: true, user_id: user.id).count }.by(1)

      bundled = Vehicle.find_by(bundled: true, user_id: user.id)
      expect(bundled.model_id).to eq(snub_model.id)
      expect(bundled.wanted).to be(false)
    end

    it "is idempotent: re-saving the parent does not duplicate the bundled child" do
      parent = create(:vehicle, user: user, model: parent_model, wanted: false)

      expect {
        parent.update!(name: "Renamed")
      }.not_to change { Vehicle.where(bundled: true, vehicle_id: parent.id).count }
    end

    it "cascades wanted state to the bundled child" do
      parent = create(:vehicle, user: user, model: parent_model, wanted: false)

      parent.update!(wanted: true)

      bundled = Vehicle.find_by(bundled: true, vehicle_id: parent.id)
      expect(bundled.wanted).to be(true)
    end

    it "destroys bundled children when the parent is destroyed" do
      parent = create(:vehicle, user: user, model: parent_model, wanted: false)

      expect {
        parent.destroy
      }.to change { Vehicle.where(bundled: true, vehicle_id: parent.id).count }.from(1).to(0)
    end

    it "does not create bundled children for a loaner vehicle" do
      loaner_parent = create(:vehicle, :loaner, user: user, model: parent_model)

      expect(Vehicle.where(bundled: true, vehicle_id: loaner_parent.id)).to be_empty
    end

    it "does not recurse: bundled child does not create grand-bundled" do
      grand_snub = create(:model)
      snub_model.snub_crafts << grand_snub

      create(:vehicle, user: user, model: parent_model, wanted: false)

      bundled_models = Vehicle.where(bundled: true, user_id: user.id).pluck(:model_id)
      expect(bundled_models).to contain_exactly(snub_model.id)
    end
  end

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
