# frozen_string_literal: true

require "test_helper"

module Contracts
  # A contract line asking for a crafted part: the recipe, and the grades it
  # wants per slot, read under the line's match rule.
  class CraftedProgressTest < ActiveSupport::TestCase
    setup do
      @fleet = create(:fleet)
      @destination = create(:fleet_inventory, fleet: @fleet)
      @contractor = create(:user)
      @contract = create(:fleet_contract, :in_progress,
        fleet: @fleet, destination_fleet_inventory: @destination)
      @contract.fleet_contract_items.destroy_all
      create(:fleet_contract_assignment, :lead, fleet_contract: @contract, user: @contractor)

      @component = create(:component, name: "Bulwark")
      @blueprint = create(:blueprint, craftable: @component)
      [1, 2].each do |position|
        slot = create(:blueprint_cost_slot, build: @blueprint.build, position:)
        create(:blueprint_cost_modifier, slot:)
      end
      @blueprint.reload
    end

    test "a crafted line takes a part crafted from its recipe at or above its grades" do
      line(qualities: {1 => 700})

      deliver(qualities: {1 => 750, 2 => 100}, quantity: 1)
      deliver(qualities: {1 => 600, 2 => 900}, quantity: 1)
      deliver(quantity: 1)

      assert_equal 1.to_d, progress.lines.first.delivered
    end

    test "an exact line takes only the grades it names" do
      line(qualities: {1 => 700}, quality_match: :exact)

      deliver(qualities: {1 => 700, 2 => 100}, quantity: 1)
      deliver(qualities: {1 => 750, 2 => 100}, quantity: 1)

      assert_equal 1.to_d, progress.lines.first.delivered
    end

    test "a crafted line with no grades takes any part crafted from its recipe" do
      line(qualities: nil)

      deliver(qualities: {1 => 10, 2 => 10}, quantity: 2)

      assert_equal 2.to_d, progress.lines.first.delivered
    end

    test "a crafted line does not take a part crafted from another recipe" do
      line(qualities: nil)
      other = create(:blueprint, craftable: @component)

      deliver(qualities: {}, quantity: 1, blueprint: other)

      assert_equal 0.to_d, progress.lines.first.delivered
    end

    # One crafted part cannot fill the crafted line and the plain line beside
    # it: it goes to the narrowest line that still has room.
    test "a contract asks for one part plain and crafted, and counts each part once" do
      crafted_line = line(qualities: {1 => 700}, quantity: 1)
      plain = create(:fleet_contract_item, fleet_contract: @contract, name: "Bulwark",
        category: :component, unit: :units, quantity: 2, item: @component)

      deliver(qualities: {1 => 800, 2 => 100}, quantity: 2)
      deliver(quantity: 1)

      lines = progress.lines.index_by { |line| line.item.id }

      assert_equal 1.to_d, lines[crafted_line.id].delivered
      assert_equal 2.to_d, lines[plain.id].delivered
    end

    test "a part answering two crafted lines goes to the stricter one" do
      strict = line(qualities: {1 => 800}, quantity: 1)
      loose = line(qualities: {1 => 500}, quantity: 1)

      deliver(qualities: {1 => 900, 2 => 100}, quantity: 1)
      deliver(qualities: {1 => 600, 2 => 100}, quantity: 1)

      lines = progress.lines.index_by { |line| line.item.id }

      assert_equal 1.to_d, lines[strict.id].delivered
      assert_equal 1.to_d, lines[loose.id].delivered
    end

    # Greedily, the part answering both would fill the line that names more
    # slots, and the part only that line takes would have nowhere to go.
    test "the deliveries fill every line they can, whatever order they arrive in" do
      narrow = line(qualities: {1 => 800}, quantity: 1)
      broad = line(qualities: {1 => 500, 2 => 100}, quantity: 1)

      deliver(qualities: {1 => 900, 2 => 200}, quantity: 1)
      deliver(qualities: {1 => 600, 2 => 200}, quantity: 1)

      lines = progress.lines.index_by { |line| line.item.id }

      assert_equal 1.to_d, lines[narrow.id].delivered
      assert_equal 1.to_d, lines[broad.id].delivered
    end

    test "a line may ask for the same grades by another rule" do
      line(qualities: {1 => 700})

      assert_predicate build_line(qualities: {1 => 700}, quality_match: :exact), :valid?
    end

    test "a new contract cannot ask for the same crafted part twice" do
      attributes = {name: "Bulwark", category: :component, unit: :units, quantity: 1,
                    item_type: "Component", item_id: @component.id,
                    crafted_blueprint_id: @blueprint.id, crafted_qualities: {"1" => 700}}

      contract = build(:fleet_contract, fleet: @fleet, destination_fleet_inventory: @destination,
        fleet_contract_items_attributes: [attributes, attributes])

      assert_not contract.valid?
      assert contract.errors[:fleet_contract_items].any?
    end

    test "a contract cannot ask for the same crafted part twice the same way" do
      line(qualities: {1 => 700})

      twin = build_line(qualities: {1 => 700})

      assert_not twin.valid?
      assert twin.errors[:name].any?
    end

    # They are that part, whatever went into them.
    test "a plain line takes crafted parts too" do
      create(:fleet_contract_item, fleet_contract: @contract, name: "Bulwark", category: :component,
        unit: :units, quantity: 3, item: @component)

      deliver(quantity: 1)
      deliver(qualities: {1 => 750, 2 => 500}, quantity: 1)

      assert_equal 2.to_d, progress.lines.first.delivered
    end

    # Goods picked up that could never count toward the line are not progress
    # on it.
    test "a crafted line counts only crafted parts as picked up" do
      line(qualities: {1 => 700})
      source = create(:fleet_inventory, fleet: @fleet)
      @contract.update!(kind: :transport, source_fleet_inventory: source)

      pick_up(source, quantity: 2)
      pick_up(source, quantity: 1, qualities: {1 => 800, 2 => 100})

      assert_equal 1.to_d, progress.lines.first.picked_up
    end

    # The stored recipe makes one part; pointing the line at another would ask
    # for something the recipe can never deliver.
    test "a line cannot move to a part its recipe does not make" do
      saved = line(qualities: nil)

      saved.item = create(:component, name: "Palisade")

      assert_not saved.valid?
      assert saved.errors[:crafted_blueprint_id].any?
    end

    test "a line asks only for grades in slots that move a stat" do
      create(:blueprint_cost_slot, build: @blueprint.build, position: 3)

      line = build_line(qualities: {3 => 500})

      assert_not line.valid?
      assert line.errors[:crafted_qualities].any?
    end

    test "a line asks for a recipe only for a part the recipe makes" do
      line = build_line(qualities: nil, blueprint: create(:blueprint, craftable: create(:component)))

      assert_not line.valid?
      assert line.errors[:crafted_blueprint_id].any?
    end

    private def build_line(qualities:, blueprint: @blueprint, quality_match: :at_least, quantity: 5)
      build(:fleet_contract_item, fleet_contract: @contract, name: "Bulwark", category: :component,
        unit: :units, quantity:, item: @component, quality_match:,
        crafted_blueprint: blueprint, crafted_qualities: qualities)
    end

    private def line(**)
      build_line(**).tap(&:save!)
    end

    private def pick_up(source, quantity:, qualities: :plain)
      create(:fleet_inventory_item, fleet_inventory: source, name: "Bulwark", category: :component,
        unit: :units, item: @component, quantity: 5, quality: nil,
        **crafted_attributes(qualities))

      transfer = create(:inventory_transfer, fleet_contract: @contract, initiated_by: @contractor,
        aasm_state: "completed", source_inventory: nil, source_fleet_inventory: source,
        destination_fleet_inventory: nil, recipient: @contractor, expires_at: 14.days.from_now)

      create(:fleet_inventory_item, fleet_inventory: source, inventory_transfer: transfer,
        entry_type: :withdrawal, name: "Bulwark", category: :component, unit: :units,
        item: @component, quantity:, quality: nil, **crafted_attributes(qualities))
    end

    private def crafted_attributes(qualities, blueprint = @blueprint)
      (qualities == :plain) ? {} : {crafted_blueprint: blueprint, crafted_qualities: qualities}
    end

    private def progress
      Contracts::Progress.new(@contract.reload)
    end

    private def deliver(quantity:, qualities: :plain, blueprint: @blueprint)
      transfer = create(:inventory_transfer, fleet_contract: @contract, initiated_by: @contractor,
        aasm_state: "completed", source_inventory: create(:inventory, holder: @contractor),
        destination_fleet_inventory: @destination)

      crafted = crafted_attributes(qualities, blueprint)

      create(:fleet_inventory_item, fleet_inventory: @destination, inventory_transfer: transfer,
        entry_type: :deposit, name: "Bulwark", category: :component, unit: :units,
        item: @component, quantity:, quality: nil, **crafted)
    end
  end
end
