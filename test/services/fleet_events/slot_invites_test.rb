# frozen_string_literal: true

require "test_helper"

class FleetEvents::SlotInvitesTest < ActiveSupport::TestCase
  setup do
    @primary = create(:user)
    @alternate = create(:user)
    @third = create(:user)
    @fleet = create(:fleet, :with_squadrons, members: [@primary, @alternate, @third])
    @squadron = create(:fleet_squadron, fleet: @fleet, flights_enabled: true)
    @rows = [@primary, @alternate, @third].map do |user|
      create(:fleet_squadron_membership, fleet_squadron: @squadron,
        fleet_membership: @fleet.fleet_memberships.kept.find_by!(user:))
    end
    @event = create(:fleet_event, fleet: @fleet)
    @slot = create(:fleet_event_slot, slottable: create(:fleet_event_team, fleet_event: @event))
    @rows.each_with_index do |row, index|
      @slot.fleet_event_slot_candidates.create!(fleet_squadron_membership: row, position: index)
    end
  end

  def membership(user)
    @fleet.fleet_memberships.kept.find_by!(user:)
  end

  def active_signup
    @slot.fleet_event_signups.where.not(status: "withdrawn").sole
  end

  test "a draft event invites nobody until it opens, then the primary" do
    FleetEvents::SlotInvites.offer_all!(@event)
    assert_empty @slot.fleet_event_signups

    @event.update!(status: "open")

    assert_equal membership(@primary), active_signup.fleet_membership
    assert active_signup.invited?
  end

  test "declining hands the slot to the next alternate as a new invitation" do
    @event.update!(status: "open")

    active_signup.withdraw!

    assert_equal membership(@alternate), active_signup.fleet_membership
    assert active_signup.invited?
    assert @slot.fleet_event_slot_candidates.find_by!(fleet_squadron_membership: @rows.first).passed_at
  end

  test "a primary already seated elsewhere in the event is skipped" do
    other_slot = create(:fleet_event_slot, slottable: @slot.slottable)
    create(:fleet_event_signup, fleet_event: @event, fleet_event_slot: other_slot, fleet_membership: membership(@primary))

    @event.update!(status: "open")

    assert_equal membership(@alternate), active_signup.fleet_membership
  end

  test "a primary who left the fleet is skipped" do
    membership(@primary).discard!

    @event.update!(status: "open")

    assert_equal membership(@alternate), active_signup.fleet_membership
  end

  test "leaving the fleet hands an invitation on" do
    @event.update!(status: "open")

    membership(@primary).discard!

    assert_equal membership(@alternate), active_signup.fleet_membership
  end

  test "a member waiting in the event pool is moved into the slot" do
    pooled = create(:fleet_event_signup, fleet_event: @event, fleet_event_slot: nil,
      fleet_membership: membership(@primary), status: "interested")

    @event.update!(status: "open")

    assert_equal pooled.id, active_signup.id
    assert active_signup.invited?
  end

  test "a recurring event invites nobody" do
    @event.update_columns(recurring: true, status: "open")

    FleetEvents::SlotInvites.offer_all!(@event.reload)

    assert_empty @slot.fleet_event_signups
  end

  test "the invited member hears about it" do
    assert_difference -> { Notification.where(user: @primary, notification_type: "fleet_event_signup_invited").count }, 1 do
      @event.update!(status: "open")
    end
  end
  test "leaving the squadron hands an invitation on" do
    @event.update!(status: "open")

    @rows.first.destroy!

    assert_equal membership(@alternate), active_signup.fleet_membership
  end

  test "a member already confirmed in the event pool keeps the commitment in the slot" do
    pooled = create(:fleet_event_signup, fleet_event: @event, fleet_event_slot: nil,
      fleet_membership: membership(@primary), status: "confirmed")

    @event.update!(status: "open")

    assert_equal pooled.id, active_signup.id
    assert active_signup.confirmed?
  end

  test "another event's open slots are left alone" do
    other = create(:fleet_event, fleet: @fleet)
    other_slot = create(:fleet_event_slot, slottable: create(:fleet_event_team, fleet_event: other))
    other_slot.fleet_event_slot_candidates.create!(fleet_squadron_membership: @rows.second, position: 0)

    @event.update!(status: "open")

    assert_empty other_slot.fleet_event_signups
  end
  test "a squadron with flights off holds its invitations and sends them when it switches back on" do
    @squadron.update!(flights_enabled: false)
    @event.update!(status: "open")

    assert_empty @slot.fleet_event_signups
    assert @slot.fleet_event_slot_candidates.all? { |candidate| candidate.passed_at.nil? }

    @squadron.update!(flights_enabled: true)

    assert_equal membership(@primary), active_signup.fleet_membership
  end
end
