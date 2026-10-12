# frozen_string_literal: true

require "test_helper"

class HangarPledgeItems::OwnedPaintsTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @model = create(:model, name: "C1 Spirit")
    @icebreak = create(:model_paint, model: @model, name: "IceBreak")
    @deck = create(:model_paint, model: @model, name: "Deck the Hull")
  end

  def owned_ids
    HangarPledgeItems::OwnedPaints.new(@user, @model).paint_ids([@icebreak, @deck])
  end

  test "matches a pledge naming the ship and the paint" do
    create(:hangar_pledge_item, user: @user, name: "Spirit - IceBreak Paint")

    assert_equal [@icebreak.id], owned_ids
  end

  test "matches a pledge that covers several ships" do
    create(:hangar_pledge_item, user: @user, name: "Archimedes & C1 Spirit - Deck the Hull Paint")

    assert_equal [@deck.id], owned_ids
  end

  test "ignores the same paint pledged for another ship" do
    create(:hangar_pledge_item, user: @user, name: "Golem - IceBreak Paint")

    assert_empty owned_ids
  end

  test "ignores a pledge naming another model outright" do
    create(:model, name: "Spirit")
    create(:hangar_pledge_item, user: @user, name: "Spirit - IceBreak Paint")

    assert_empty owned_ids
  end

  test "matches an older pledge that runs ship and paint together" do
    model = create(:model, name: "Constellation Andromeda")
    paint = create(:model_paint, model:, name: "Invictus Blue and Gold")
    create(:hangar_pledge_item, user: @user, name: "2950 Invictus Constellation Blue and Gold")

    assert_equal [paint.id], HangarPledgeItems::OwnedPaints.new(@user, model).paint_ids([paint])
  end

  test "ignores an older pledge for another series" do
    model = create(:model, name: "Retaliator Bomber")
    paint = create(:model_paint, model:, name: "Invictus Blue and Gold")
    create(:hangar_pledge_item, user: @user, name: "2950 Invictus Constellation Blue and Gold")

    assert_empty HangarPledgeItems::OwnedPaints.new(@user, model).paint_ids([paint])
  end

  test "ignores another user's pledges" do
    create(:hangar_pledge_item, name: "Spirit - IceBreak Paint")

    assert_empty owned_ids
  end

  test "ignores flair and equipment" do
    create(:hangar_pledge_item, user: @user, kind: "flair", name: "Spirit - IceBreak Paint")

    assert_empty owned_ids
  end
end
