# frozen_string_literal: true

require "test_helper"

module Discord
  class PostJoinRequestJobTest < ActiveSupport::TestCase
    OFFICERS = "555555555555555555"

    setup do
      @fleet = create(:fleet, name: "Test Wing")
      @setting = @fleet.create_fleet_notification_setting!(discord_guild_id: "guild-1", discord_officers_channel_id: OFFICERS)
      ApiClient.stubs(:configured?).returns(true)
      @api = mock("Discord::ApiClient")
      ApiClient.stubs(:new).returns(@api)
      @api.stubs(:get_channel).with(OFFICERS).returns({"guild_id" => "guild-1"})
      PostJoinRequestJob.clear
      RefreshJoinRequestMessageJob.clear

      @membership = @fleet.fleet_memberships.create!(user: create(:user, username: "Newcomer"), fleet_role: @fleet.fleet_roles.find_by(name: "Member"))
    end

    test "requesting to join enqueues the post when the fleet has an officers channel" do
      @membership.request!

      assert_equal [@membership.id], PostJoinRequestJob.jobs.map { |job| job["args"].first }
    end

    test "nothing is enqueued without an officers channel" do
      @setting.update!(discord_officers_channel_id: nil)

      @membership.request!

      assert_empty PostJoinRequestJob.jobs
    end

    test "the request is posted to the officers channel with both buttons" do
      @membership.update!(aasm_state: "requested")

      @api.expects(:create_message).with { |channel_id, payload|
        channel_id == OFFICERS &&
          payload[:content].include?("Newcomer") &&
          payload[:components].first[:components].map { |button| button[:custom_id] } ==
            %w[accept decline].map { |decision| JoinRequestMessage.custom_id(decision, @membership.id) }
      }.returns({"id" => "777", "channel_id" => OFFICERS})

      PostJoinRequestJob.new.perform(@membership.id)
    end

    test "the posted message is remembered on the membership" do
      @membership.update!(aasm_state: "requested")
      @api.stubs(:create_message).returns({"id" => "777", "channel_id" => OFFICERS})

      PostJoinRequestJob.new.perform(@membership.id)

      assert_equal [OFFICERS, "777"], @membership.reload.values_at(:discord_request_channel_id, :discord_request_message_id)
      assert_empty RefreshJoinRequestMessageJob.jobs
    end

    # Its answer committed before the message id was stored, so the answer
    # found nothing to update.
    test "a request answered while the post was on its way is refreshed right after" do
      @membership.update!(aasm_state: "requested")
      RefreshJoinRequestMessageJob.clear
      @api.stubs(:create_message).with { |*|
        FleetMembership.where(id: @membership.id).update_all(aasm_state: "declined")
      }.returns({"id" => "777", "channel_id" => OFFICERS})

      PostJoinRequestJob.new.perform(@membership.id)

      assert_equal [@membership.id], RefreshJoinRequestMessageJob.jobs.map { |job| job["args"].first }
    end

    test "a request answered while the job waited is not posted" do
      @membership.update!(aasm_state: "accepted")
      @api.expects(:create_message).never

      PostJoinRequestJob.new.perform(@membership.id)
    end

    # Every member reads the fleet's channel; a join request is officers' business.
    test "an officers channel that is also the fleet's channel gets nothing" do
      @setting.update!(discord_announcement_channel_id: OFFICERS)
      @membership.update!(aasm_state: "requested")
      @api.expects(:create_message).never

      PostJoinRequestJob.new.perform(@membership.id)
    end
  end
end
