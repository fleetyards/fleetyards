# frozen_string_literal: true

require "test_helper"

# `User.with_feature` reads Flipper's gates as a query, which the transfer
# pickers need: they are searched and paginated in SQL, so a per-row
# `Flipper.enabled?` would filter one page at a time.
class UserFeatureScopesTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @other = create(:user)
  end

  test "admits the actors a feature was switched on for, and nobody else" do
    Flipper.enable_actor("hangar_inventories", @user)

    assert_equal [@user.id], User.with_feature(:hangar_inventories).pluck(:id)
  end

  test "admits everybody once the feature is on outright" do
    Flipper.enable("hangar_inventories")

    assert_includes User.with_feature(:hangar_inventories).pluck(:id), @other.id
  end

  test "admits nobody for a feature nothing has switched on" do
    assert_empty User.with_feature(:hangar_inventories)
  end

  # `testers` is the one registered group a User can be in, and it is a column.
  test "admits the testers group" do
    @other.update!(tester: true)
    Flipper.enable_group("hangar_inventories", :testers)

    assert_equal [@other.id], User.with_feature(:hangar_inventories).pluck(:id)
  end

  # A percentage rollout cannot be written as a query. Admitting everybody
  # offers somebody the gate may still refuse, which is the harmless way round;
  # admitting nobody would hide people who can in fact receive.
  test "admits everybody under a percentage rollout it cannot express" do
    Flipper.enable_percentage_of_actors("hangar_inventories", 50)

    assert_includes User.with_feature(:hangar_inventories).pluck(:id), @other.id
  end

  # Both flags, because a transfer to a person lands in their own hangar
  # inventory -- the same pair `Inventories::TransferGate` asks for.
  test "receiving_transfers wants the feature and the surface together" do
    Flipper.enable_actor("inventory_transfers", @user)
    Flipper.enable_actor("hangar_inventories", @user)
    Flipper.enable_actor("inventory_transfers", @other)

    assert_equal [@user.id], User.receiving_transfers.pluck(:id)
  end

  # The picker must not offer somebody the send would then refuse.
  test "receiving_transfers agrees with the gate it mirrors" do
    Flipper.enable_actor("inventory_transfers", @user)
    Flipper.enable_actor("hangar_inventories", @user)

    [@user, @other].each do |user|
      gate = ::Inventories::TransferGate.new(sender: create(:user), recipient: user)

      assert_equal User.receiving_transfers.exists?(id: user.id),
        gate.refusal&.code != :unavailable
    end
  end
end
