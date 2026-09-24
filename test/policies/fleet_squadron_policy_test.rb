# frozen_string_literal: true

require "test_helper"

# The trap this covers: the read rule is stated twice -- once for a single
# record by `show?`, once in SQL by the relation scope the list endpoint uses.
# A change to one that misses the other serves a squadron on the list that
# `show` still refuses, or the other way round.
class FleetSquadronPolicyTest < ActiveSupport::TestCase
  setup do
    @admin = create(:user)
    @officer = create(:user)
    @member = create(:user)
    @stranger = create(:user)
    @fleet = create(:fleet, admins: [@admin], officers: [@officer], members: [@member])

    @squadron = create(:fleet_squadron, fleet: @fleet)
    @other_squadron = create(:fleet_squadron, fleet: @fleet)
  end

  def policy_for(reader, record = nil)
    FleetSquadronPolicy.new(record, user: reader, fleet: @fleet)
  end

  def scoped(reader)
    policy_for(reader)
      .apply_scope(FleetSquadron.where(fleet: @fleet), type: :active_record_relation)
      .to_a
  end

  def member_with(privileges)
    role = create(:fleet_role, fleet: @fleet,
      name: "Policy Test #{privileges.join("-").presence || "none"}",
      resource_access: privileges)
    create(:user).tap do |user|
      create(:fleet_membership, :accepted, fleet: @fleet, user: user, fleet_role: role)
    end
  end

  test "the relation scope and the record check agree for every reader" do
    readers = [@admin, @officer, @member, @stranger, member_with([]), member_with(["fleet:squadrons:delete"])]

    readers.each do |reader|
      listed = scoped(reader)

      [@squadron, @other_squadron].each do |squadron|
        shown = policy_for(reader, squadron).apply(:show?)

        assert_equal shown, listed.include?(squadron),
          "the scope and show? disagreed about #{squadron.name} for #{reader.username}"
      end
    end
  end

  test "every seeded role reads the squadron list" do
    [@admin, @officer, @member].each do |reader|
      assert_equal [@squadron, @other_squadron].sort_by(&:id), scoped(reader).sort_by(&:id),
        "#{reader.username} could not list the fleet's squadrons"
    end
  end

  test "somebody outside the fleet reads nothing" do
    assert_empty scoped(@stranger)
    refute policy_for(@stranger, @squadron).apply(:show?)
  end

  # A role holding a write privilege but not the read one still has to reach
  # the record, or the lookup in front of its own `authorize!` would answer 404
  # for a write the record rule allows. Squadrons have no per-record visibility,
  # so the scope is the only lookup and it carries the read gate -- which makes
  # this the one combination worth stating outright.
  test "the seeded roles that may write may also read" do
    assert policy_for(@admin, @squadron).apply(:create?)
    assert policy_for(@admin, @squadron).apply(:update?)
    assert policy_for(@admin, @squadron).apply(:destroy?)
    assert policy_for(@admin, @squadron).apply(:show?)
  end

  test "an officer organises members but does not decide which squadrons exist" do
    assert FleetSquadronMembershipPolicy.new(nil, user: @officer, fleet: @fleet).apply(:create?)
    refute policy_for(@officer, @squadron).apply(:create?)
    refute policy_for(@officer, @squadron).apply(:update?)
    refute policy_for(@officer, @squadron).apply(:destroy?)
  end

  test "a plain member reads but changes nothing" do
    assert policy_for(@member, @squadron).apply(:show?)
    refute policy_for(@member, @squadron).apply(:create?)
    refute policy_for(@member, @squadron).apply(:update?)
    refute policy_for(@member, @squadron).apply(:destroy?)
    refute FleetSquadronMembershipPolicy.new(nil, user: @member, fleet: @fleet).apply(:create?)
  end

  test "the manage privilege stands in for every specific one" do
    manager = member_with(["fleet:squadrons:manage"])

    assert policy_for(manager, @squadron).apply(:show?)
    assert policy_for(manager, @squadron).apply(:create?)
    assert policy_for(manager, @squadron).apply(:update?)
    assert policy_for(manager, @squadron).apply(:destroy?)
    assert FleetSquadronMembershipPolicy.new(nil, user: manager, fleet: @fleet).apply(:create?)
  end

  test "the relation scope says so rather than answering none without a fleet" do
    assert_raises(ArgumentError) do
      FleetSquadronPolicy.new(nil, user: @admin)
        .apply_scope(FleetSquadron.all, type: :active_record_relation)
    end
  end
end
