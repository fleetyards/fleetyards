# frozen_string_literal: true

require "test_helper"

class FleetSquadronMembershipPolicyTest < ActiveSupport::TestCase
  setup do
    @officer = create(:user)
    @fleet = create(:fleet, officers: [@officer])
    @squadron = create(:fleet_squadron, fleet: @fleet)
    @other_squadron = create(:fleet_squadron, fleet: @fleet, team: true)
    @ranks = @fleet.fleet_squadron_roles.index_by(&:key)

    @leader, @leader_row = ranked("leader")
    @co_leader, @co_leader_row = ranked("co_leader")
    @squadron_officer, @squadron_officer_row = ranked("officer")
    @member, @member_row = ranked("member")
  end

  # A plain fleet member holding `key` in @squadron, so whatever they may do
  # comes from the squadron rank alone.
  def ranked(key)
    user = create(:user)
    membership = create(:fleet_membership, :accepted, fleet: @fleet, user:)
    row = create(:fleet_squadron_membership, fleet_squadron: @squadron, fleet_membership: membership, fleet_squadron_role: @ranks.fetch(key))
    [user, row]
  end

  def allowed?(user, rule, record)
    FleetSquadronMembershipPolicy.new(record, user:, fleet: @fleet).apply(rule)
  end

  def promote(row, key)
    FleetSquadronMembership.find(row.id).tap { |reloaded| reloaded.fleet_squadron_role = @ranks.fetch(key) }
  end

  def probe(squadron = @squadron)
    FleetSquadronMembership.new(fleet_squadron: squadron)
  end

  test "a Leader, Co-Leader or Officer manages their own squadron's roster" do
    [@leader, @co_leader, @squadron_officer].each do |user|
      assert allowed?(user, :create?, probe), "#{user.username} could not add members"
    end

    refute allowed?(@member, :create?, probe)
  end

  test "a squadron rank grants nothing in another squadron" do
    refute allowed?(@leader, :create?, probe(@other_squadron))
    refute allowed?(@leader, :manage_ranks?, probe(@other_squadron))
  end

  test "only a Leader or Co-Leader manages ranks" do
    assert allowed?(@leader, :manage_ranks?, probe)
    assert allowed?(@co_leader, :manage_ranks?, probe)
    refute allowed?(@squadron_officer, :manage_ranks?, probe)
    refute allowed?(@member, :manage_ranks?, probe)
  end

  test "removing a member needs to outrank them" do
    assert allowed?(@squadron_officer, :destroy?, @member_row)
    refute allowed?(@squadron_officer, :destroy?, @co_leader_row)
    refute allowed?(@squadron_officer, :destroy?, @leader_row)
    assert allowed?(@co_leader, :destroy?, @squadron_officer_row)
    refute allowed?(@co_leader, :destroy?, @leader_row)
    assert allowed?(@leader, :destroy?, @co_leader_row)
  end

  test "a Leader appoints officers and the Co-Leader, but not another Leader" do
    assert allowed?(@leader, :update?, promote(@member_row, "officer"))
    assert allowed?(@leader, :update?, promote(@squadron_officer_row, "member"))
    refute allowed?(@leader, :update?, promote(@member_row, "leader"))
  end

  test "neither an Officer nor a Co-Leader changes the Leader's rank" do
    refute allowed?(@co_leader, :update?, promote(@leader_row, "officer"))
    refute allowed?(@squadron_officer, :update?, promote(@leader_row, "member"))
  end

  test "a Co-Leader cannot promote anyone to their own rank or above" do
    assert allowed?(@co_leader, :update?, promote(@member_row, "officer"))
    refute allowed?(@co_leader, :update?, promote(@member_row, "co_leader"))
  end

  test "an Officer cannot change ranks at all" do
    refute allowed?(@squadron_officer, :update?, promote(@member_row, "officer"))
  end

  test "anyone may step down, never up" do
    assert allowed?(@leader, :update?, promote(@leader_row, "officer"))
    assert allowed?(@squadron_officer, :update?, promote(@squadron_officer_row, "member"))
    refute allowed?(@squadron_officer, :update?, promote(@squadron_officer_row, "co_leader"))
  end

  test "editing a join date follows the removal rule" do
    officer_row = FleetSquadronMembership.find(@member_row.id).tap { |row| row.created_at = 1.year.ago }
    leader_row = FleetSquadronMembership.find(@leader_row.id).tap { |row| row.created_at = 1.year.ago }

    assert allowed?(@squadron_officer, :update?, officer_row)
    refute allowed?(@squadron_officer, :update?, leader_row)
  end

  test "a fleet-wide privilege covers every squadron and every rank" do
    assert allowed?(@officer, :create?, probe(@other_squadron))
    assert allowed?(@officer, :manage_ranks?, probe)
    assert allowed?(@officer, :destroy?, @leader_row)
    assert allowed?(@officer, :update?, promote(@member_row, "leader"))
  end
end
