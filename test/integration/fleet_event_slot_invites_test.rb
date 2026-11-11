# frozen_string_literal: true

require "test_helper"

class FleetEventSlotInvitesTest < ActionDispatch::IntegrationTest
  setup do
    Flipper.enable("fleet_mission_builder")
    @admin = create(:user)
    @member = create(:user)
    @alternate = create(:user)
    @fleet = create(:fleet, :with_squadrons, admins: [@admin], members: [@member, @alternate])
    @event = create(:fleet_event, :open, fleet: @fleet, created_by: @admin, signup_approval: "confirmation_required")
    @slot = create(:fleet_event_slot, slottable: create(:fleet_event_team, fleet_event: @event))
    squadron = create(:fleet_squadron, fleet: @fleet)
    [@member, @alternate].each_with_index do |user, index|
      row = create(:fleet_squadron_membership, fleet_squadron: squadron,
        fleet_membership: @fleet.fleet_memberships.kept.find_by!(user:))
      @slot.fleet_event_slot_candidates.create!(fleet_squadron_membership: row, position: index)
    end
    @invite = FleetEvents::SlotInvites.new(@slot).offer!
    sign_in @member
  end

  test "accepting an invitation confirms it without waiting for approval" do
    patch "/api/v1/fleet-event-slots/#{@slot.id}/signup", params: {status: "confirmed"}, as: :json

    assert_response :success
    assert_equal "confirmed", @invite.reload.status
  end

  test "accepting through the signup button confirms it as well" do
    post "/api/v1/fleet-event-slots/#{@slot.id}/signup", params: {status: "confirmed"}, as: :json

    assert_response :success
    assert_equal "confirmed", @invite.reload.status
  end

  test "declining an invitation offers the slot to the alternate" do
    delete "/api/v1/fleet-event-slots/#{@slot.id}/signup", as: :json

    assert_response :no_content
    seated = @slot.fleet_event_signups.where.not(status: "withdrawn").sole
    assert_equal @alternate, seated.fleet_membership.user
    assert seated.invited?
  end
end
