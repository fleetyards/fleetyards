# frozen_string_literal: true

require "test_helper"

class HangarSyncPledgeDetailsTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @model = create(:model, name: "Cutlass Black")
  end

  test "a synced ship keeps what its pledge credits and whether RSI lets it melt" do
    sync([{id: "1", name: "Cutlass Black", type: "ship", pledge_value: "110.00", meltable: true, pledge_item_count: 3}])

    vehicle = @user.vehicles.find_by!(rsi_pledge_id: "1")
    assert_in_delta 110.0, vehicle.rsi_pledge_value
    assert vehicle.rsi_pledge_meltable
    assert_equal 3, vehicle.rsi_pledge_item_count

    sync([{id: "1", name: "Cutlass Black", type: "ship", pledge_value: "110.00", meltable: false, pledge_item_count: 3}])

    assert_not vehicle.reload.rsi_pledge_meltable
  end

  test "a sync that sends no meltable flag leaves it unknown" do
    sync([{id: "2", name: "Cutlass Black", type: "ship"}])

    assert_nil @user.vehicles.find_by!(rsi_pledge_id: "2").rsi_pledge_meltable
  end

  private def sync(items)
    HangarSync.new(items).run(@user.id)
  end
end
