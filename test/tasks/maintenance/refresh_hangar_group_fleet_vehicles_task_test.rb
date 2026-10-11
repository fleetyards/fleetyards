# frozen_string_literal: true

require "test_helper"

module Maintenance
  class RefreshHangarGroupFleetVehiclesTaskTest < ActiveSupport::TestCase
    setup do
      @task = ::Maintenance::RefreshHangarGroupFleetVehiclesTask.new
      @user = create(:user)
      @group = create(:hangar_group, user: @user)
      @membership = create(:fleet_membership, :accepted, user: @user, ships_filter: "hangar_group", hangar_group_id: @group.id)
    end

    test "#collection is the accepted memberships sharing by hangar group" do
      sharing_all = create(:fleet_membership, :accepted, ships_filter: "all")
      invited = create(:fleet_membership, :invited, ships_filter: "hangar_group", hangar_group_id: @group.id)

      ids = @task.collection.pluck(:id)

      assert_includes ids, @membership.id
      assert_not_includes ids, sharing_all.id
      assert_not_includes ids, invited.id
    end

    # The state a bulk-filing hangar sync left: the ship and its loaner sit in
    # the group, and the fleet lists neither.
    test "#process lists a grouped ship and its loaner the fleet is missing" do
      loaner_model = create(:model)
      parent_model = create(:model).tap { |model| model.loaners << loaner_model }
      parent = create(:vehicle, user: @user, model: parent_model, wanted: false)
      loaner = Vehicle.find_by!(loaner: true, vehicle_id: parent.id)
      TaskForce.insert_all([{vehicle_id: parent.id, hangar_group_id: @group.id, created_at: Time.current, updated_at: Time.current}])
      FleetVehicle.where(fleet_id: @membership.fleet_id).delete_all

      @task.process(@membership)

      assert_equal [loaner.id, parent.id].sort, FleetVehicle.where(fleet_id: @membership.fleet_id).pluck(:vehicle_id).sort
    end
  end
end
