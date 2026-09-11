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

# Nothing a user did to their own ship was recorded: the old guard needed an
# `author_id`, which is an `attr_accessor` only an admin action sets. Recording
# the owner's edits means the machine writes have to be held out by something
# else, and these are the paths that would otherwise bury them.
class VehicleVersioningTest < ActiveSupport::TestCase
  def versions_for(vehicle)
    PaperTrail::Version.where(item_type: "Vehicle", item_id: vehicle.id)
  end

  test "a rename records a version carrying the change" do
    vehicle = create(:vehicle)

    assert_difference -> { versions_for(vehicle).count }, 1 do
      vehicle.update!(name: "Renamed by its owner")
    end

    assert_equal [nil, "Renamed by its owner"],
      versions_for(vehicle).order(created_at: :desc).first.changeset["name"]
  end

  test "a repaint records a version" do
    vehicle = create(:vehicle)
    paint = create(:model_paint, model: vehicle.model)

    assert_difference -> { versions_for(vehicle).count }, 1 do
      vehicle.update!(model_paint_id: paint.id)
    end

    assert_equal paint.id,
      versions_for(vehicle).order(created_at: :desc).first.changeset["model_paint_id"].last
  end

  test "a retrofit records a version" do
    vehicle = create(:vehicle)
    other_model = create(:model)

    assert_difference -> { versions_for(vehicle).count }, 1 do
      vehicle.update!(model_id: other_model.id)
    end
  end

  test "adding a ship records its first version" do
    vehicle = create(:vehicle)

    assert_equal ["create"], versions_for(vehicle).pluck(:event)
  end

  test "a loaner records nothing of its own" do
    user = create(:user)
    loaner_model = create(:model)
    parent_model = create(:model).tap { |model| model.loaners << loaner_model }

    parent = create(:vehicle, user:, model: parent_model, wanted: false)
    loaner = Vehicle.find_by!(loaner: true, vehicle_id: parent.id)

    assert_empty versions_for(loaner)

    # The parent save recomputes the loaner's `wanted`, which is in `only:`.
    assert_no_difference -> { versions_for(loaner).count } do
      parent.update!(wanted: true)
    end
  end

  test "a bundled snub craft records nothing of its own" do
    user = create(:user)
    snub_model = create(:model)
    parent_model = create(:model).tap { |model| model.snub_crafts << snub_model }

    parent = create(:vehicle, user:, model: parent_model, wanted: false)
    bundled = Vehicle.find_by!(bundled: true, vehicle_id: parent.id)

    assert_empty versions_for(bundled)

    assert_no_difference -> { versions_for(bundled).count } do
      parent.update!(wanted: true)
    end
  end

  test "a write inside a disabled block records nothing" do
    vehicle = create(:vehicle)

    assert_no_difference -> { versions_for(vehicle).count } do
      PaperTrail.request(enabled: false) do
        vehicle.update!(name: "Renamed by a sync")
      end
    end
  end

  test "update_columns records nothing" do
    vehicle = create(:vehicle)

    assert_no_difference -> { versions_for(vehicle).count } do
      vehicle.update_columns(wanted: true, updated_at: Time.zone.now)
    end
  end

  test "a destroyed ship keeps no versions" do
    vehicle = create(:vehicle)
    vehicle.update!(name: "Renamed by its owner")

    vehicle.destroy!

    assert_empty versions_for(vehicle)
  end

  # Modules and upgrades are destroyed and recreated wholesale on every PATCH
  # that names them, so versioning them would record churn, not change.
  test "a module change records nothing" do
    vehicle = create(:vehicle)
    model_module = create(:model_module)

    assert_no_difference -> { PaperTrail::Version.where(item_type: "VehicleModule").count } do
      vehicle.vehicle_modules.create!(model_module:)
    end
  end
end

class VehicleDeleteWithDependentsTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
  end

  test "takes the loadouts and the rows hanging off the vehicle" do
    vehicle = create(:vehicle, user: @user)
    create(:vehicle_loadout, vehicle: vehicle)
    TaskForce.create!(vehicle: vehicle, hangar_group: create(:hangar_group, user: @user))
    FleetVehicle.create!(fleet: create(:fleet), vehicle: vehicle)

    Vehicle.delete_with_dependents([vehicle.id])

    assert_empty Vehicle.where(id: vehicle.id)
    assert_empty VehicleLoadout.where(vehicle_id: vehicle.id)
    assert_empty TaskForce.where(vehicle_id: vehicle.id)
    assert_empty FleetVehicle.where(vehicle_id: vehicle.id)
    assert_empty PaperTrail::Version.where(item_type: "Vehicle", item_id: vehicle.id)
  end

  test "takes the loaners and bundled snub crafts of the vehicles it deletes" do
    loaner_model = create(:model)
    snub_craft_model = create(:model)
    parent_model = create(:model).tap do |model|
      model.loaners << loaner_model
      model.snub_crafts << snub_craft_model
    end
    parent = create(:vehicle, user: @user, model: parent_model)

    assert_equal 2, Vehicle.where(vehicle_id: parent.id).count

    Vehicle.delete_with_dependents([parent.id])

    assert_empty Vehicle.where(vehicle_id: parent.id)
  end

  test "leaves a visible loaner behind when the visible one is deleted" do
    loaner_model = create(:model)
    parent_model = create(:model).tap { |model| model.loaners << loaner_model }
    other_parent_model = create(:model).tap { |model| model.loaners << loaner_model }
    create(:vehicle, user: @user, model: parent_model)
    create(:vehicle, user: @user, model: other_parent_model)

    visible = Vehicle.find_by(loaner: true, user_id: @user.id, model_id: loaner_model.id, hidden: false)

    Sidekiq::Worker.clear_all

    Vehicle.delete_with_dependents([visible.parent_vehicle.id])

    remaining = Vehicle.where(loaner: true, user_id: @user.id, model_id: loaner_model.id)
    assert_equal 1, remaining.count
    assert_equal 1, remaining.where(hidden: false).count

    # Queued from `after_all_transactions_commit`, so a worker cannot read the
    # hangar as it was before the delete.
    assert_equal [remaining.first.id], Updater::FleetVehicleUpdateJob.jobs.map { |job| job["args"].first }
  end

  test "detaches a ship inventory under a name no sibling holds" do
    model = create(:model)
    first = create(:vehicle, user: @user, model: model)
    second = create(:vehicle, user: @user, model: model)
    Inventory.provision_for(first, holder: @user)
    Inventory.provision_for(second, holder: @user)

    Vehicle.delete_with_dependents([first.id, second.id])

    inventories = Inventory.where(holder: @user)
    assert_equal 2, inventories.count
    assert_equal 2, inventories.pluck(:name).uniq.size
    assert_equal 2, inventories.pluck(:slug).uniq.size
    assert_equal [model.name, model.name], inventories.pluck(:location)
    assert_equal [nil, nil], inventories.pluck(:vehicle_id)
  end

  # An inventory left invalid by something else entirely must not be what stops
  # somebody deleting a ship, and the label still has to land.
  test "detaches an inventory that no longer validates" do
    vehicle = create(:vehicle, user: @user)
    inventory = Inventory.provision_for(vehicle, holder: @user)
    inventory.update_column(:name, "")
    assert_not inventory.reload.valid?

    Vehicle.find(vehicle.id).destroy!

    assert_nil Vehicle.find_by(id: vehicle.id)
    assert_equal vehicle.display_name, inventory.reload.location
  end

  # What keeps two inventories detaching at once from choosing the same suffix:
  # the read is locked, and ordered so neither waits on a row the other holds.
  test "claims the name under a lock taken in a fixed order" do
    vehicle = create(:vehicle, user: @user)
    Inventory.provision_for(vehicle, holder: @user)

    claim = statements_for { Vehicle.find(vehicle.id).destroy! }
      .find { |sql| sql.include?("inventories") && sql.include?("FOR UPDATE") }

    assert claim, "the name claim takes no lock"
    assert_includes claim, %(ORDER BY "inventories"."id")
  end

  test "detaches a ship inventory on a single destroy too" do
    model = create(:model)
    first = create(:vehicle, user: @user, model: model)
    second = create(:vehicle, user: @user, model: model)
    Inventory.provision_for(first, holder: @user)
    Inventory.provision_for(second, holder: @user)

    Vehicle.find(first.id).destroy!
    Vehicle.find(second.id).destroy!

    assert_equal 2, Inventory.where(holder: @user).pluck(:name).uniq.size
  end

  private def statements_for
    statements = []
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
      statements << payload[:sql] unless payload[:name] == "SCHEMA"
    end

    yield
    statements
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end
end
