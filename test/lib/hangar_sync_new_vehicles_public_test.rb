# frozen_string_literal: true

require "test_helper"

class HangarSyncNewVehiclesPublicTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @model = create(:model, name: "Cutlass Black")
  end

  test "a synced ship starts in the public hangar by default" do
    sync([{id: "1", name: "Cutlass Black", type: "ship"}])

    assert_predicate @user.vehicles.find_by!(rsi_pledge_id: "1"), :public?
  end

  test "a synced ship stays hidden when the owner hides new ships" do
    @user.update!(new_vehicles_public: false)

    sync([{id: "1", name: "Cutlass Black", type: "ship"}])

    assert_not_predicate @user.vehicles.find_by!(rsi_pledge_id: "1"), :public?
  end

  test "a sync leaves the visibility of a ship it already knows alone" do
    vehicle = create(:vehicle, user: @user, model: @model, rsi_pledge_id: "1", public: false)

    sync([{id: "1", name: "Cutlass Black", type: "ship"}])

    assert_not_predicate vehicle.reload, :public?
  end

  private def sync(items)
    HangarSync.new(items).run(@user.id)
  end
end
