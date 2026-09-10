# frozen_string_literal: true

# == Schema Information
#
# Table name: vehicles
#
#  id                   :uuid             not null, primary key
#  alternative_names    :string
#  bought_via           :integer          default(0)
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
require "test_helper"

class VehicleTest < ActiveSupport::TestCase
  should belong_to(:user)
  should belong_to(:model)
  should belong_to(:model_paint).optional(true)
  should belong_to(:module_package).optional(true)
end

class VehicleBundledSnubCraftsTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @snub_model = create(:model)
    @parent_model = create(:model).tap { |m| m.snub_crafts << @snub_model }
  end

  test "auto-creates a bundled child for each model.snub_crafts entry" do
    assert_difference -> { Vehicle.where(bundled: true, user_id: @user.id).count }, 1 do
      create(:vehicle, user: @user, model: @parent_model, wanted: false)
    end

    bundled = Vehicle.find_by(bundled: true, user_id: @user.id)
    assert_equal @snub_model.id, bundled.model_id
    assert_equal false, bundled.wanted
  end

  test "is idempotent: re-saving the parent does not duplicate the bundled child" do
    parent = create(:vehicle, user: @user, model: @parent_model, wanted: false)

    assert_no_difference -> { Vehicle.where(bundled: true, vehicle_id: parent.id).count } do
      parent.update!(name: "Renamed")
    end
  end

  test "cascades wanted state to the bundled child" do
    parent = create(:vehicle, user: @user, model: @parent_model, wanted: false)

    parent.update!(wanted: true)

    bundled = Vehicle.find_by(bundled: true, vehicle_id: parent.id)
    assert_equal true, bundled.wanted
  end

  test "destroys bundled children when the parent is destroyed" do
    parent = create(:vehicle, user: @user, model: @parent_model, wanted: false)
    assert_equal 1, Vehicle.where(bundled: true, vehicle_id: parent.id).count

    parent.destroy

    assert_equal 0, Vehicle.where(bundled: true, vehicle_id: parent.id).count
  end

  test "does not create bundled children for a loaner vehicle" do
    loaner_parent = create(:vehicle, :loaner, user: @user, model: @parent_model)

    assert_empty Vehicle.where(bundled: true, vehicle_id: loaner_parent.id)
  end

  test "does not recurse: bundled child does not create grand-bundled" do
    grand_snub = create(:model)
    @snub_model.snub_crafts << grand_snub

    create(:vehicle, user: @user, model: @parent_model, wanted: false)

    bundled_models = Vehicle.where(bundled: true, user_id: @user.id).pluck(:model_id)
    assert_equal [@snub_model.id], bundled_models
  end
end

class VehicleLoanersTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @loaner_model = create(:model)
    @parent_model = create(:model).tap { |m| m.loaners << @loaner_model }
  end

  test "auto-creates a loaner for each model.loaners entry" do
    assert_difference -> { Vehicle.where(loaner: true, user_id: @user.id).count }, 1 do
      create(:vehicle, user: @user, model: @parent_model, wanted: false)
    end

    loaner = Vehicle.find_by(loaner: true, user_id: @user.id)
    assert_equal @loaner_model.id, loaner.model_id
    assert_equal false, loaner.wanted
  end

  test "is idempotent: re-saving the parent does not duplicate the loaner" do
    parent = create(:vehicle, user: @user, model: @parent_model, wanted: false)

    assert_no_difference -> { Vehicle.where(loaner: true, vehicle_id: parent.id).count } do
      parent.update!(name: "Renamed")
    end
  end

  test "cascades wanted state to the loaner" do
    parent = create(:vehicle, user: @user, model: @parent_model, wanted: false)

    parent.update!(wanted: true)

    loaners = Vehicle.where(loaner: true, vehicle_id: parent.id)
    assert_equal 1, loaners.count
    assert_equal true, loaners.first.wanted
  end

  # The lookup used to be scoped by `wanted`, so a flip missed the existing row,
  # created a second one and stranded the first with the old value -- which is
  # what put loaners of wishlisted ships into fleets.
  test "flipping wanted back and forth strands no loaner" do
    parent = create(:vehicle, user: @user, model: @parent_model, wanted: false)

    parent.update!(wanted: true)
    parent.update!(wanted: false)

    loaners = Vehicle.where(loaner: true, vehicle_id: parent.id)
    assert_equal 1, loaners.count
    assert_equal false, loaners.first.wanted
  end

  # The `hidden` recomputation matched the row it was about, so a visible loaner
  # answered "yes, a visible loaner exists" about itself and hid itself on the
  # parent's next save.
  test "re-saving the parent does not hide its only loaner" do
    parent = create(:vehicle, user: @user, model: @parent_model, wanted: false)
    assert_equal false, Vehicle.find_by(loaner: true, vehicle_id: parent.id).hidden

    parent.update!(name: "Renamed")

    assert_equal false, Vehicle.find_by(loaner: true, vehicle_id: parent.id).hidden
  end

  test "keeps exactly one visible loaner when two parents loan the same model" do
    other_parent_model = create(:model).tap { |m| m.loaners << @loaner_model }

    create(:vehicle, user: @user, model: @parent_model, wanted: false)
    create(:vehicle, user: @user, model: other_parent_model, wanted: false)

    loaners = Vehicle.where(loaner: true, user_id: @user.id, model_id: @loaner_model.id)
    assert_equal 2, loaners.count
    assert_equal 1, loaners.where(hidden: false).count
  end

  test "destroys loaners when the parent is destroyed" do
    parent = create(:vehicle, user: @user, model: @parent_model, wanted: false)
    assert_equal 1, Vehicle.where(loaner: true, vehicle_id: parent.id).count

    parent.destroy

    assert_equal 0, Vehicle.where(loaner: true, vehicle_id: parent.id).count
  end

  test "does not create loaners for a loaner vehicle" do
    loaner_parent = create(:vehicle, :loaner, user: @user, model: @parent_model)

    assert_empty Vehicle.where(loaner: true, vehicle_id: loaner_parent.id)
  end
end

class VehicleScheduleFleetVehicleUpdateTest < ActiveSupport::TestCase
  setup do
    @vehicle = create(:vehicle)
    Sidekiq::Worker.clear_all
  end

  test "enqueues update job on purchase change" do
    @vehicle.update!(wanted: !@vehicle.wanted)
    assert_operator Updater::FleetVehicleUpdateJob.jobs.size, :>=, 1
  end

  test "does not enqueue update job if vehicle is hidden" do
    @vehicle.update!(hidden: true)
    Sidekiq::Worker.clear_all

    @vehicle.update!(wanted: !@vehicle.wanted)

    assert_equal 0, Updater::FleetVehicleUpdateJob.jobs.size
  end
end
