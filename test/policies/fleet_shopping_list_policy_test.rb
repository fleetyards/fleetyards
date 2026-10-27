# frozen_string_literal: true

require "test_helper"

# The rule is stated twice: in Ruby by `FleetShoppingList#visible_to?` for one
# record, and in SQL by the policy's relation scope for a list. These keep the
# two in agreement.
class FleetShoppingListPolicyTest < ActiveSupport::TestCase
  setup do
    @officer = create(:user)
    @member = create(:user)
    @pilot = create(:user)
    @stranger = create(:user)
    @fleet = create(:fleet, officers: [@officer], members: [@member, @pilot])

    @squadron = create(:fleet_squadron, fleet: @fleet)
    create(:fleet_squadron_membership, fleet_squadron: @squadron,
      fleet_membership: @fleet.fleet_memberships.find_by!(user: @pilot))

    @open = create(:fleet_shopping_list, fleet: @fleet)
    @closed = create(:fleet_shopping_list, fleet: @fleet, visibility: :officers_only)
    @squad = create(:fleet_shopping_list, fleet: @fleet, visibility: :squadron_only, fleet_squadrons: [@squadron])
  end

  def policy_for(reader, record = nil)
    FleetShoppingListPolicy.new(record, user: reader, fleet: @fleet)
  end

  def scoped(reader, name = :default)
    policy_for(reader)
      .apply_scope(FleetShoppingList.where(fleet: @fleet), type: :active_record_relation, name: name)
      .to_a
  end

  test "the relation scope and the record check agree for every reader" do
    [@officer, @member, @pilot, @stranger].each do |reader|
      listed = scoped(reader)

      [@open, @closed, @squad].each do |list|
        assert_equal policy_for(reader, list).apply(:show?), listed.include?(list),
          "the scope and show? disagreed about the #{list.visibility} list for #{reader.username}"
      end
    end
  end

  test "each reader is listed what their rank and squadron allow" do
    assert_equal [@open, @closed, @squad].to_set, scoped(@officer).to_set
    assert_equal [@open], scoped(@member)
    assert_equal [@open, @squad].to_set, scoped(@pilot).to_set
    assert_empty scoped(@stranger)
  end

  test "only officers may publish, update or delete by default" do
    assert policy_for(@officer, @fleet.fleet_shopping_lists.new).apply(:create?)
    refute policy_for(@member, @fleet.fleet_shopping_lists.new).apply(:create?)
    refute policy_for(@pilot, @squad).apply(:update?)
    refute policy_for(@pilot, @squad).apply(:destroy?)
    assert policy_for(@pilot, @squad).apply(:copy?)
  end
end
