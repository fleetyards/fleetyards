# frozen_string_literal: true

require "test_helper"

class HangarPledgeItems::OwnedPaintsTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @model = create(:model, name: "Nomad")
    @ice_break = create(:model_paint, model: @model, name: "Ice Break")
    @other = create(:model_paint, model: @model, name: "Deck the Hull")
  end

  def owned_ids(user = @user)
    HangarPledgeItems::OwnedPaints.new(user).paint_ids([@ice_break, @other])
  end

  test "owns the paints the user's pledges are linked to" do
    item = create(:hangar_pledge_item, user: @user, name: "Nomad IceBreak Livery")
    HangarPledgeItemModelPaint.create!(hangar_pledge_item: item, model_paint: @ice_break)

    assert_equal [@ice_break.id], owned_ids
  end

  test "ignores another user's linked pledges" do
    item = create(:hangar_pledge_item, name: "Nomad IceBreak Livery")
    HangarPledgeItemModelPaint.create!(hangar_pledge_item: item, model_paint: @ice_break)

    assert_empty owned_ids
  end

  test "ignores a pledge that resolved to nothing" do
    create(:hangar_pledge_item, user: @user, name: "Something RSI renamed")

    assert_empty owned_ids
  end
end
