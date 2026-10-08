# frozen_string_literal: true

require "test_helper"

class FleetMembershipDiscardTest < ActiveSupport::TestCase
  setup do
    @creator = create(:user)
    @member = create(:user)
  end

  test "discarding a membership with a permanent role is blocked" do
    fleet = create(:fleet, created_by: @creator.id)
    admin_membership = fleet.fleet_memberships.find_by(user_id: @creator.id)

    assert admin_membership.fleet_role.permanent?
    assert_not admin_membership.discard
    assert admin_membership.reload.kept?
  end

  test "a discarded membership is hidden from the fleet's kept members" do
    fleet = create(:fleet, created_by: @creator.id, members: [@member])
    membership = fleet.fleet_memberships.find_by(user_id: @member.id)

    assert membership.discard

    assert_not fleet.fleet_memberships.kept.exists?(user_id: @member.id)
  end

  test "a discarded membership is excluded from the user's fleets" do
    fleet = create(:fleet, created_by: @creator.id, members: [@member])
    @member.fleet_memberships.find_by(fleet_id: fleet.id).discard

    assert_not @member.reload.fleets.exists?(fleet.id)
  end

  test "a user can rejoin a fleet after their membership was discarded" do
    fleet = create(:fleet, created_by: @creator.id, members: [@member])
    fleet.fleet_memberships.find_by(user_id: @member.id).discard

    rejoined = fleet.fleet_memberships.build(user: @member, fleet_role: fleet.default_member_role)

    assert rejoined.valid?, rejoined.errors.full_messages.to_sentence
    assert rejoined.save
  end

  def signup_for(membership, event, **attributes)
    slot = create(:fleet_event_slot, slottable: create(:fleet_event_team, fleet_event: event))
    create(:fleet_event_signup, fleet_event_slot: slot, fleet_membership: membership, **attributes)
  end

  test "discarding a membership frees the seats it holds in upcoming events" do
    fleet = create(:fleet, created_by: @creator.id, members: [@member])
    membership = fleet.fleet_memberships.find_by(user_id: @member.id)
    event = create(:fleet_event, :open, fleet:, starts_at: 1.day.from_now)
    signup = signup_for(membership, event)

    assert membership.discard

    assert signup.reload.withdrawn?
    assert_equal 0, event.signups_count
  end

  test "an upcoming occurrence of a recurring event is freed, a past one is kept" do
    fleet = create(:fleet, created_by: @creator.id, members: [@member])
    membership = fleet.fleet_memberships.find_by(user_id: @member.id)
    event = create(:fleet_event, :open, fleet:, starts_at: 2.weeks.ago, recurring: true,
      recurrence_interval: "weekly", recurrence_count: 10)
    upcoming = signup_for(membership, event, occurrence_date: 1.week.from_now.to_date)
    past = signup_for(membership, event, occurrence_date: 1.week.ago.to_date)

    assert membership.discard

    assert upcoming.reload.withdrawn?
    assert_equal "confirmed", past.reload.status
  end

  test "signups for events already over stay as the record of who flew" do
    fleet = create(:fleet, created_by: @creator.id, members: [@member])
    membership = fleet.fleet_memberships.find_by(user_id: @member.id)
    over = create(:fleet_event, :open, fleet:, starts_at: 2.days.ago, ends_at: 1.day.ago)
    completed = create(:fleet_event, fleet:, status: "completed", starts_at: 1.hour.from_now)
    kept = [signup_for(membership, over), signup_for(membership, completed)]

    assert membership.discard

    assert_equal %w[confirmed confirmed], kept.map { |signup| signup.reload.status }
  end

  test "today's occurrence of a recurring event is kept once it has ended" do
    travel_to Time.zone.local(2026, 10, 8, 16, 0) do
      fleet = create(:fleet, created_by: @creator.id, members: [@member])
      membership = fleet.fleet_memberships.find_by(user_id: @member.id)
      ended = create(:fleet_event, :open, fleet:, recurring: true, recurrence_interval: "weekly",
        recurrence_count: 10, starts_at: Time.zone.local(2026, 9, 24, 9, 0), ends_at: Time.zone.local(2026, 9, 24, 11, 0))
      tonight = create(:fleet_event, :open, fleet:, recurring: true, recurrence_interval: "weekly",
        recurrence_count: 10, starts_at: Time.zone.local(2026, 9, 24, 20, 0), ends_at: Time.zone.local(2026, 9, 24, 22, 0))
      flown = signup_for(membership, ended, occurrence_date: Date.current)
      upcoming = signup_for(membership, tonight, occurrence_date: Date.current)

      assert membership.discard

      assert_equal "confirmed", flown.reload.status
      assert upcoming.reload.withdrawn?
    end
  end

  test "a freed seat tells the event's creator, as a withdrawal does" do
    fleet = create(:fleet, created_by: @creator.id, members: [@member])
    membership = fleet.fleet_memberships.find_by(user_id: @member.id)
    signup = signup_for(membership, create(:fleet_event, :open, fleet:, starts_at: 1.day.from_now))
    withdrawn = []

    ActiveSupport::Notifications.subscribed(->(*, payload) { withdrawn << payload[:signup] }, "fleet_event_signup.withdrawn") do
      assert membership.discard
    end

    assert_equal [signup], withdrawn
  end

  test "a discarded membership cannot take a new seat" do
    fleet = create(:fleet, created_by: @creator.id, members: [@member])
    membership = fleet.fleet_memberships.find_by(user_id: @member.id)
    event = create(:fleet_event, :open, fleet:, starts_at: 1.day.from_now)
    slot = create(:fleet_event_slot, slottable: create(:fleet_event_team, fleet_event: event))
    signup = build(:fleet_event_signup, fleet_event_slot: slot, fleet_membership: membership)
    FleetMembership.where(id: membership.id).update_all(discarded_at: Time.current)

    assert_not signup.save
    assert signup.errors.added?(:fleet_membership_id, :not_a_member)
  end

  test "a signup loaded before the discard cannot be promoted after it" do
    fleet = create(:fleet, created_by: @creator.id, members: [@member])
    membership = fleet.fleet_memberships.find_by(user_id: @member.id)
    event = create(:fleet_event, :open, fleet:, starts_at: 1.day.from_now)
    slot = create(:fleet_event_slot, slottable: create(:fleet_event_team, fleet_event: event))
    stale = create(:fleet_event_signup, fleet_event: event, fleet_event_slot: nil, fleet_membership: membership, status: "interested")

    assert membership.discard
    assert_not stale.update(fleet_event_slot: slot, status: "confirmed")
    assert stale.errors.added?(:fleet_membership_id, :not_a_member)
    assert stale.reload.withdrawn?
  end
end
