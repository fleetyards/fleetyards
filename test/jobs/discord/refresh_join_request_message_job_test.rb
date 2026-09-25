# frozen_string_literal: true

require "test_helper"

module Discord
  class RefreshJoinRequestMessageJobTest < ActiveSupport::TestCase
    CHANNEL = "555555555555555555"
    MESSAGE = "777777777777777777"

    setup do
      ApiClient.stubs(:configured?).returns(true)
      @api = mock("Discord::ApiClient")
      ApiClient.stubs(:new).returns(@api)
      RefreshJoinRequestMessageJob.clear

      @fleet = create(:fleet, name: "Test Wing")
      @membership = @fleet.fleet_memberships.create!(user: create(:user, username: "Newcomer"), fleet_role: @fleet.fleet_roles.find_by(name: "Member"))
      @membership.update!(aasm_state: "requested")
      @membership.update_columns(discord_request_channel_id: CHANNEL, discord_request_message_id: MESSAGE)
    end

    def disabled?(payload)
      payload[:components].first[:components].all? { |button| button[:disabled] }
    end

    test "answering a request with a message queues its refresh" do
      @membership.answer_request(accept: true)

      assert_equal [[@membership.id, CHANNEL, MESSAGE]], RefreshJoinRequestMessageJob.jobs.map { |job| job["args"] }
    end

    test "withdrawing a request queues its refresh" do
      @membership.discard!

      assert_equal 1, RefreshJoinRequestMessageJob.jobs.size
    end

    test "a change that leaves the request pending queues nothing" do
      @membership.update!(nickname: "Newbie")

      assert_empty RefreshJoinRequestMessageJob.jobs
    end

    test "a request answered on the website shows the outcome with the buttons disabled" do
      @membership.update!(aasm_state: "accepted")

      @api.expects(:edit_message).with { |channel_id, message_id, payload|
        channel_id == CHANNEL && message_id == MESSAGE &&
          payload[:content].include?(I18n.t("discord.join_request.accepted")) && disabled?(payload)
      }

      RefreshJoinRequestMessageJob.new.perform(@membership.id)
    end

    test "a withdrawn request reads as no longer pending" do
      @membership.discard!

      @api.expects(:edit_message).with { |_, _, payload| payload[:content].include?(I18n.t("discord.join_request.closed")) && disabled?(payload) }

      RefreshJoinRequestMessageJob.new.perform(@membership.id)
    end

    test "a destroyed request keeps its text and loses its buttons" do
      id = @membership.id
      FleetMembership.where(id: id).delete_all

      @api.expects(:edit_message).with { |channel_id, message_id, payload|
        channel_id == CHANNEL && message_id == MESSAGE && payload[:content].nil? && disabled?(payload)
      }

      RefreshJoinRequestMessageJob.new.perform(id, CHANNEL, MESSAGE)
    end

    test "a request still pending is left alone" do
      @api.expects(:edit_message).never

      RefreshJoinRequestMessageJob.new.perform(@membership.id)
    end

    test "a request that was never posted is left alone" do
      @membership.update_columns(discord_request_channel_id: nil, discord_request_message_id: nil, aasm_state: "accepted")
      @api.expects(:edit_message).never

      RefreshJoinRequestMessageJob.new.perform(@membership.id)
    end

    test "a deleted message is not retried" do
      @membership.update!(aasm_state: "declined")
      @api.expects(:edit_message).raises(ApiClient::Error.new(404, "Unknown Message"))

      assert_nothing_raised { RefreshJoinRequestMessageJob.new.perform(@membership.id) }
    end
  end
end
