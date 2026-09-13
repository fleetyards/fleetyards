# frozen_string_literal: true

require "test_helper"

# The trap this covers: `show?` already admitted on `public_fleet_stats?`, so
# folding the three rules into one shared helper would have let
# `allies_fleet_stats` quietly open the fleet page as well.
class Public::FleetPolicyTest < ActiveSupport::TestCase
  setup do
    @owner = create(:user)
    @fleet = create(:fleet, created_by: @owner.id, public_fleet: false)
    @ally_member, @allied_fleet = allied_reader
    @stranger = create(:user)
  end

  # Traits rather than a state name: pending is the factory's default and has
  # no trait of its own.
  def allied_reader(fleet = @fleet, traits: [:accepted])
    reader = create(:user)
    allied_fleet = create(:fleet, created_by: reader.id)
    create(:fleet_alliance, *traits, requester: fleet, addressee: allied_fleet)
    [reader, allied_fleet]
  end

  def allowed?(rule, reader)
    Public::FleetPolicy.new(@fleet, user: reader).public_send(rule)
  end

  test "a closed fleet shows nothing to an ally until it says so" do
    %i[show? show_stats? show_members?].each do |rule|
      refute allowed?(rule, @ally_member), "#{rule} was open with every switch off"
    end
  end

  test "each ally switch opens only its own surface" do
    {
      allies_fleet: :show?,
      allies_fleet_stats: :show_stats?,
      allies_fleet_members: :show_members?
    }.each do |column, rule|
      @fleet.update!(column => true)

      assert allowed?(rule, @ally_member), "#{rule} stayed closed with #{column} on"
      refute allowed?(rule, @stranger), "#{rule} was open to a stranger with #{column} on"

      @fleet.update!(column => false)
    end
  end

  # allies_fleet_stats admits show? as well, exactly as public_fleet_stats has
  # always done -- a fleet sharing only its numbers still needs a page to put
  # them on. allies_fleet_members must not.
  test "the stats switch opens the page, and the roster switch does not" do
    @fleet.update!(allies_fleet_stats: true)

    assert allowed?(:show?, @ally_member)
    refute allowed?(:show_members?, @ally_member)

    @fleet.update!(allies_fleet_stats: false, allies_fleet_members: true)

    refute allowed?(:show?, @ally_member)
    refute allowed?(:show_stats?, @ally_member)
    assert allowed?(:show_members?, @ally_member)
  end

  test "the fleet's own members read everything without any ally switch" do
    %i[show? show_stats? show_members?].each do |rule|
      assert allowed?(rule, @owner), "#{rule} was closed to the fleet's own admin"
    end
  end

  test "a pending alliance reads nothing" do
    @fleet.update!(allies_fleet: true, allies_fleet_stats: true, allies_fleet_members: true)
    pending_reader, = allied_reader(traits: [])

    %i[show? show_stats? show_members?].each do |rule|
      refute allowed?(rule, pending_reader), "#{rule} was open to a pending alliance"
    end
  end

  test "a discarded ally reads nothing" do
    @fleet.update!(allies_fleet: true, allies_fleet_stats: true, allies_fleet_members: true)
    @allied_fleet.discard

    %i[show? show_stats? show_members?].each do |rule|
      refute allowed?(rule, @ally_member), "#{rule} was open through a discarded fleet"
    end
  end

  # User#fleets follows kept memberships in any state, so reading the alliance
  # through it rather than through accepted memberships would make an unanswered
  # invitation enough.
  test "an unanswered invitation to an allied fleet is not membership of it" do
    @fleet.update!(allies_fleet_members: true)
    invitee = create(:user)
    @allied_fleet.fleet_memberships.create!(user: invitee, fleet_role: @allied_fleet.default_member_role).invite!

    refute allowed?(:show_members?, invitee)
  end

  test "public still wins for everybody" do
    @fleet.update!(public_fleet: true)

    assert allowed?(:show?, @stranger)
    assert allowed?(:show?, nil)
  end

  test "an anonymous reader is never an ally" do
    @fleet.update!(allies_fleet: true, allies_fleet_stats: true, allies_fleet_members: true)

    %i[show? show_stats? show_members?].each do |rule|
      refute allowed?(rule, nil), "#{rule} was open to an anonymous reader"
    end
  end
end
