# frozen_string_literal: true

require "test_helper"

class VersionedItemTest < ActiveSupport::TestCase
  test "#find raises for a type paper_trail does not watch" do
    admin_user = create(:admin_user)

    assert_raises(ActiveRecord::RecordNotFound) { VersionedItem.find("AdminUser", admin_user.id) }
  end

  test "#find raises for a blank type" do
    assert_raises(ActiveRecord::RecordNotFound) { VersionedItem.find(nil, nil) }
  end

  test "#authorization_root resolves a catalogue to itself" do
    model = create(:model)

    assert_equal [model, ::Admin::ModelPolicy], VersionedItem.authorization_root(model)
  end

  test "#authorization_root resolves a fleet role to its fleet" do
    role = create(:fleet_role, name: "Quartermaster")

    assert_equal [role.fleet, ::Admin::FleetPolicy], VersionedItem.authorization_root(role)
  end

  test "#authorization_root resolves an inventory item to whoever holds the inventory" do
    user = create(:user)
    inventory = create(:inventory, holder: user)
    item = create(:inventory_item, inventory:)

    assert_equal [user, ::Admin::UserPolicy], VersionedItem.authorization_root(item)
  end

  # A holder that was deleted leaves nothing to ask, which is a denial rather
  # than a crash.
  test "#authorization_root is nil when the chain runs out" do
    assert_nil VersionedItem.authorization_root(Inventory.new)
  end
end
