# frozen_string_literal: true

require "test_helper"

# == Schema Information
#
# Table name: inventories
#
#  id          :uuid             not null, primary key
#  description :text
#  holder_type :string           not null
#  location    :string
#  name        :string           not null
#  slug        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  holder_id   :uuid             not null
#  vehicle_id  :uuid
#
# Indexes
#
#  index_inventories_on_holder_and_lower_name               (holder_type, holder_id, lower((name)::text)) UNIQUE WHERE (vehicle_id IS NULL)
#  index_inventories_on_holder_type_and_holder_id           (holder_type,holder_id)
#  index_inventories_on_holder_type_and_holder_id_and_slug  (holder_type,holder_id,slug) UNIQUE WHERE (vehicle_id IS NULL)
#  index_inventories_on_vehicle_id                          (vehicle_id) UNIQUE WHERE (vehicle_id IS NOT NULL)
#
# Foreign Keys
#
#  fk_rails_...  (vehicle_id => vehicles.id) ON DELETE => nullify
#
class InventoryTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @inventory = create(:inventory, holder: @user, name: "Area 18 Locker")
  end

  test "generates a slug from the name" do
    assert_equal "area-18-locker", @inventory.slug
  end

  test "names are unique per user but not across users" do
    duplicate = build(:inventory, holder: @user, name: "area 18 locker")

    assert_not duplicate.valid?

    other = build(:inventory, holder: create(:user), name: "Area 18 Locker")

    assert_predicate other, :valid?
  end

  test "current_stock nets deposits against withdrawals" do
    create(:inventory_item, inventory: @inventory, name: "Quantanium", quantity: 100, unit: :scu)
    create(:inventory_item, inventory: @inventory, name: "Quantanium", quantity: 30, unit: :scu, entry_type: :withdrawal)
    create(:inventory_item, inventory: @inventory, name: "Titanium", quantity: 20, unit: :scu)

    stock = @inventory.current_stock

    assert_equal 70, stock.find { |s| s.name == "Quantanium" }.net_quantity
    assert_equal 20, stock.find { |s| s.name == "Titanium" }.net_quantity
  end

  test "current_stock omits fully withdrawn entries" do
    create(:inventory_item, inventory: @inventory, name: "Quantanium", quantity: 50, unit: :scu)
    create(:inventory_item, inventory: @inventory, name: "Quantanium", quantity: 50, unit: :scu, entry_type: :withdrawal)

    assert_empty @inventory.current_stock
  end

  test "destroying the inventory destroys its ledger entries" do
    create_list(:inventory_item, 2, inventory: @inventory)

    assert_difference "InventoryItem.count", -2 do
      @inventory.destroy
    end
  end

  test "ship inventories are exempt from the name uniqueness rule" do
    model = create(:model, name: "Ironclad")
    first = create(:vehicle, user: @user, model:)
    second = create(:vehicle, user: @user, model:)

    create(:inventory, holder: @user, vehicle: first, name: "Ironclad Inventory")
    duplicate = build(:inventory, holder: @user, vehicle: second, name: "Ironclad Inventory")

    assert_predicate duplicate, :valid?
    assert_nothing_raised { duplicate.save! }
  end

  test "a vehicle holds at most one inventory" do
    vehicle = create(:vehicle, user: @user)
    create(:inventory, holder: @user, vehicle:)

    assert_raises ActiveRecord::RecordNotUnique do
      create(:inventory, holder: @user, vehicle:, name: "Second Hold")
    end
  end

  test "the default name falls back from the ship name to the model name" do
    model = create(:model, name: "Ironclad")

    assert_equal "Ironclad Inventory", create(:vehicle, user: @user, model:).default_inventory_name
    assert_equal(
      "Rustbucket Inventory",
      create(:vehicle, user: @user, model:, name: "Rustbucket").default_inventory_name
    )
  end

  test "selling the ship keeps the stock and remembers where it was" do
    vehicle = create(:vehicle, user: @user, model: create(:model, name: "Ironclad"))
    inventory = create(:inventory, holder: @user, vehicle:, name: "Ironclad Inventory")
    create(:inventory_item, inventory:, name: "Quantanium", quantity: 42, unit: :scu)

    assert_no_difference ["Inventory.count", "InventoryItem.count"] do
      vehicle.destroy
    end

    inventory.reload

    assert_nil inventory.vehicle_id
    assert_equal "Ironclad", inventory.location
    assert_equal "Ironclad Inventory", inventory.name
  end

  test "provisioning names the inventory after the ship and is idempotent" do
    vehicle = create(:vehicle, user: @user, model: create(:model, name: "Ironclad"))

    inventory = assert_difference("Inventory.count", 1) do
      Inventory.provision_for(vehicle, holder: @user)
    end

    assert_equal "Ironclad Inventory", inventory.name

    assert_no_difference "Inventory.count" do
      assert_equal inventory, Inventory.provision_for(vehicle, holder: @user)
    end
  end

  test "a first deposit that loses the race adopts the row the winner wrote" do
    vehicle = create(:vehicle, user: @user)
    winner = Inventory.create!(holder: @user, vehicle:, name: "Winner")

    # Going straight at `create_for` is what a request whose existence check came
    # back empty does, and the row being there already is the race it lost. The
    # surrounding transaction is the deposit it is in the middle of writing.
    inventory = assert_no_difference "Inventory.count" do
      Inventory.transaction { Inventory.create_for(vehicle, holder: @user) }
    end

    assert_equal winner, inventory
    assert_predicate create(:inventory_item, inventory:), :persisted?
  end

  test "an existing location survives the ship being sold" do
    vehicle = create(:vehicle, user: @user)
    inventory = create(:inventory, holder: @user, vehicle:, location: "Port Olisar")

    vehicle.destroy

    assert_equal "Port Olisar", inventory.reload.location
  end
  # `update_stock_item` moves a whole position in one `update_all`, which runs no
  # callbacks and so filed no version -- the widest-reaching change on the
  # ledger was the only one that left no trace.
  test "update_stock_item files a version for every entry it moves" do
    stock_item = stock_position(quantity: 100, withdrawn: 30)

    assert_difference -> { versions_for(@inventory).count }, 2 do
      @inventory.update_stock_item(stock_item, {name: "Quantanium Ore"})
    end
  end

  test "update_stock_item records the old and the new name" do
    stock_item = stock_position(quantity: 100)

    @inventory.update_stock_item(stock_item, {name: "Quantanium Ore"})

    version = versions_for(@inventory).last

    assert_equal "update", version.event
    assert_equal ["Quantanium", "Quantanium Ore"], version.changeset["name"]
  end

  test "update_stock_item records a category and unit move as well" do
    stock_item = stock_position(quantity: 100)

    @inventory.update_stock_item(stock_item, {category: "component", unit: "units"})

    changeset = versions_for(@inventory).last.changeset

    assert_equal ["commodity", "component"], changeset["category"]
    assert_equal ["scu", "units"], changeset["unit"]
  end

  # The whole point of a version here is to answer what the position used to be,
  # so `object` has to hold the state before the change rather than after it.
  test "update_stock_item versions reify to the position as it was" do
    stock_item = stock_position(quantity: 100)

    @inventory.update_stock_item(stock_item, {name: "Quantanium Ore", category: "component", unit: "units"})

    was = versions_for(@inventory).last.reify

    assert_equal "Quantanium", was.name
    assert_equal "commodity", was.category
    assert_equal "scu", was.unit
  end

  test "update_stock_item attributes the move to the acting user" do
    stock_item = stock_position(quantity: 100)
    PaperTrail.request.whodunnit = @user.id

    @inventory.update_stock_item(stock_item, {name: "Quantanium Ore"})

    assert_equal @user.id, versions_for(@inventory).last.whodunnit
  end

  test "update_stock_item files nothing for a rejected change" do
    stock_item = stock_position(quantity: 100)

    assert_no_difference -> { versions_for(@inventory).count } do
      changed = @inventory.update_stock_item(stock_item, {name: "  "})

      assert_predicate changed, :invalid?
    end

    assert_equal ["Quantanium"], @inventory.inventory_items.reload.pluck(:name)
  end

  # Re-submitting the name a position already has moves nothing but `updated_at`,
  # and a version whose changeset says only that is the noise
  # `Maintenance::DropChangelessVersionsTask` exists to clear out again.
  test "update_stock_item files nothing when the position does not move" do
    stock_item = stock_position(quantity: 100)

    assert_no_difference -> { versions_for(@inventory).count } do
      @inventory.update_stock_item(stock_item, {name: "Quantanium"})
    end
  end

  # The rename and its versions are one transaction, so the failure mode the
  # fix has to avoid -- a position that moved with nothing recording it -- is
  # not reachable by a recording that blows up half way.
  test "update_stock_item rolls the rename back when the versions cannot be written" do
    stock_item = stock_position(quantity: 100, withdrawn: 30)
    ::Versions::BulkUpdateRecorder.stubs(:record).raises(ActiveRecord::StatementInvalid, "versions gone")

    assert_raises(ActiveRecord::StatementInvalid) do
      @inventory.update_stock_item(stock_item, {name: "Quantanium Ore"})
    end

    assert_equal ["Quantanium"], @inventory.inventory_items.reload.pluck(:name).uniq
    assert_empty versions_for(@inventory)
  end

  # What separates these versions from an edit to a single entry, which the
  # inventory offers on purpose and which stays revertable on its own.
  test "update_stock_item marks the versions as a whole-position move" do
    stock_item = stock_position(quantity: 100, withdrawn: 30)

    @inventory.update_stock_item(stock_item, {name: "Quantanium Ore"})

    assert_equal [InventoryStock::POSITION_MOVE_REASON], versions_for(@inventory).pluck(:reason).uniq
  end

  # The bulk statement skips validations, which is what lets a position move
  # while the per-entry rule refuses to move one entry out of it.
  test "update_stock_item moves a shared position the entries could not move themselves" do
    stock_item = stock_position(quantity: 100, withdrawn: 30)

    changed = @inventory.update_stock_item(stock_item, {name: "Quantanium Ore"})

    assert_predicate changed, :valid?
    assert_equal ["Quantanium Ore"], @inventory.inventory_items.reload.pluck(:name).uniq
  end

  test "update_stock_item leaves other positions unversioned" do
    stock_item = stock_position(quantity: 100)
    create(:inventory_item, inventory: @inventory, name: "Titanium", category: :commodity, unit: :scu, quantity: 5)
    titanium = @inventory.inventory_items.find_by(name: "Titanium")

    @inventory.update_stock_item(stock_item, {name: "Quantanium Ore"})

    assert_empty PaperTrail::Version.where(item_type: "InventoryItem", item_id: titanium.id, event: "update")
  end

  private def stock_position(quantity:, withdrawn: nil)
    create(:inventory_item, inventory: @inventory,
      name: "Quantanium", category: :commodity, unit: :scu, quantity:)

    if withdrawn.present?
      create(:inventory_item, :withdrawal, inventory: @inventory,
        name: "Quantanium", category: :commodity, unit: :scu, quantity: withdrawn)
    end

    PaperTrail::Version.where(item_type: "InventoryItem").delete_all

    @inventory.stock_item(InventoryStockItem.slug_for(name: "Quantanium", category: "commodity", unit: "scu"))
  end

  private def versions_for(inventory)
    PaperTrail::Version.where(item_type: "InventoryItem", item_id: inventory.inventory_items.select(:id)).order(:created_at)
  end
end
