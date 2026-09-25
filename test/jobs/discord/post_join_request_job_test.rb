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

      @api.expects(:create_message).with do |channel_id, payload|
        channel_id == OFFICERS &&
          payload[:content].include?("Newcomer") &&
          payload[:components].first[:components].map { |button| button[:custom_id] } ==
            %w[accept decline].map { |decision| JoinRequestMessage.custom_id(decision, @membership.id) }
      end

      PostJoinRequestJob.new.perform(@membership.id)
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
