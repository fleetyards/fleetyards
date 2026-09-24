# frozen_string_literal: true

require "test_helper"

# The rule itself, over the three models that carry it: an event, a contract
# and an inventory. Parameterised because they differ only in what their
# `visibility` column calls the restricted value.
class SquadronRestrictableTest < ActiveSupport::TestCase
  CARRIERS = {
    fleet_event: FleetEvent,
    fleet_contract: FleetContract,
    fleet_inventory: FleetInventory
  }.freeze

  setup do
    @fleet = create(:fleet)
    @combat = create(:fleet_squadron, fleet: @fleet, name: "Combat")
    @mining = create(:fleet_squadron, fleet: @fleet, name: "Mining")
    @in_combat = create(:fleet_membership, :accepted, fleet: @fleet)
    @elsewhere = create(:fleet_membership, :accepted, fleet: @fleet)

    create(:fleet_squadron_membership, fleet_squadron: @combat, fleet_membership: @in_combat)
  end

  CARRIERS.each do |factory, model|
    restricted = model.squadron_visibility_value

    test "#{factory}: an unrestricted record is visible to anybody" do
      record = create(factory, fleet: @fleet)

      assert record.visible_to_squadrons_of?(@elsewhere)
      assert record.visible_to_squadrons_of?(nil)
    end

    test "#{factory}: a restricted record is visible inside its squadron" do
      record = restrict(create(factory, fleet: @fleet), @combat)

      assert record.visible_to_squadrons_of?(@in_combat)
    end

    test "#{factory}: a restricted record is not visible outside it" do
      record = restrict(create(factory, fleet: @fleet), @combat)

      refute record.visible_to_squadrons_of?(@elsewhere)
      refute record.visible_to_squadrons_of?(nil)
    end

    test "#{factory}: several squadrons each reach it" do
      record = restrict(create(factory, fleet: @fleet), @combat, @mining)
      in_mining = create(:fleet_membership, :accepted, fleet: @fleet)
      create(:fleet_squadron_membership, fleet_squadron: @mining, fleet_membership: in_mining)

      assert record.visible_to_squadrons_of?(@in_combat)
      assert record.visible_to_squadrons_of?(in_mining)
    end

    # The scope is what the lists use and the method is what `show?` uses, so
    # the two have to answer alike or a list serves what opening it refuses.
    test "#{factory}: the scope agrees with the record" do
      open_record = create(factory, fleet: @fleet)
      mine = restrict(create(factory, fleet: @fleet), @combat)
      theirs = restrict(create(factory, fleet: @fleet), @mining)

      visible = model.where(fleet_id: @fleet.id).for_squadrons_of(@in_combat)

      assert_equal [open_record, mine].map(&:id).sort, visible.map(&:id).sort
      refute_includes visible.map(&:id), theirs.id
    end

    test "#{factory}: without a membership the scope keeps only the open ones" do
      open_record = create(factory, fleet: @fleet)
      restrict(create(factory, fleet: @fleet), @combat)

      visible = model.where(fleet_id: @fleet.id).for_squadrons_of(nil)

      assert_equal [open_record.id], visible.map(&:id)
    end

    test "#{factory}: restricted to nothing is refused" do
      record = create(factory, fleet: @fleet)
      record.visibility = restricted

      refute_predicate record, :valid?
      assert_includes record.errors.details[:visibility].pluck(:error), :needs_a_squadron
    end

    test "#{factory}: another fleet's squadron is refused" do
      record = create(factory, fleet: @fleet)
      record.fleet_squadrons = [create(:fleet_squadron, fleet: create(:fleet))]

      refute_predicate record, :valid?
      assert_includes record.errors.details[:fleet_squadrons].pluck(:error), :not_this_fleets
    end

    # Assigning ids to a saved record writes the join rows at once, ahead of
    # validation, so the refusal has to take them back with it -- a stray row
    # would let the other fleet's squadron see the record.
    test "#{factory}: an update naming another fleet's squadron leaves no assignment behind" do
      record = create(factory, fleet: @fleet)
      foreign = create(:fleet_squadron, fleet: create(:fleet))

      refute record.update(visibility: restricted, fleet_squadron_ids: [foreign.id])
      assert_empty record.reload.fleet_squadrons
      refute FleetSquadronAssignment.exists?(fleet_squadron_id: foreign.id)
    end

    # Left restricted to a squadron that no longer exists, the record would be
    # visible to nobody and would fail validation on its next save.
    test "#{factory}: disbanding its last squadron releases it" do
      record = restrict(create(factory, fleet: @fleet), @combat)

      @combat.destroy!

      refute_predicate record.reload, :squadron_restricted?
      assert_predicate record, :valid?
    end

    test "#{factory}: disbanding one of several leaves it restricted" do
      record = restrict(create(factory, fleet: @fleet), @combat, @mining)

      @combat.destroy!

      assert_predicate record.reload, :squadron_restricted?
      assert_equal [@mining.id], record.fleet_squadron_ids
    end
  end

  private def restrict(record, *squadrons)
    record.fleet_squadrons = squadrons
    record.update!(visibility: record.class.squadron_visibility_value)
    record
  end
end
