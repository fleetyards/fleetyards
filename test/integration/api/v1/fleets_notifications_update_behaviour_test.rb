# frozen_string_literal: true

require "test_helper"

class Api::V1::FleetsNotificationsUpdateBehaviourTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:user)
    @fleet = create(:fleet, admins: [@admin])
    sign_in @admin
  end

  test "names the field when a server's name is saved as its id" do
    patch "/api/v1/fleets/#{@fleet.slug}/notifications", params: {discordGuildId: "Stanton Haulers [SHL]"}, as: :json

    assert_response :bad_request
    error = JSON.parse(response.body)["errors"].sole
    assert_equal "discordGuildId", error["attribute"]
    assert_match "numeric ID", error["messages"].sole["message"]
    assert_nil @fleet.reload.fleet_notification_setting&.discord_guild_id
  end
end
