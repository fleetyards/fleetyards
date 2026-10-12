# frozen_string_literal: true

require "test_helper"

class HangarPledgeItems::SyncTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @paint = create(:model_paint, model: create(:model, name: "Nomad"), name: "Ice Break")
  end

  test "links each synced paint to the catalogue paint it is" do
    items = [{id: "1001", type: "skin", name: "Nomad IceBreak Livery"}]

    HangarPledgeItems::Sync.new(@user, items, kinds: ["paint"]).run

    item = @user.hangar_pledge_items.paints.sole
    assert_equal [@paint], item.model_paints.to_a
  end
end
