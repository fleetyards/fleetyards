# frozen_string_literal: true

require "asyncapi_helper"

# The same payload the REST list serves, pushed as a send moves through it. The
# deliveries are embedded in it, so one message carries the whole row.
class AdminAnnouncementsChannelTest < AsyncapiTestCase
  asyncapi_schema "cable/admin/v1/schema"

  channel "admin_announcements:{admin_user_gid}", channel_class: AdminAnnouncementsChannel do
    parameter :admin_user_gid,
      description: "GlobalID param of the subscribed admin user, derived from the connection",
      client_supplied: false

    broadcast "An announcement's send made progress" do
      operationId "receiveAdminAnnouncement"
      message ::Admin::V1::Schemas::Announcement
    end
  end

  test "broadcasts the announcement when its status moves" do
    admin_user = create(:admin_user)
    announcement = create(:announcement)

    payloads = assert_asyncapi_broadcast(params: {admin_user_gid: admin_user.to_gid_param}) do
      announcement.update!(status: :publishing)
    end

    assert_equal "publishing", payloads.first["status"]
  end

  test "broadcasts the announcement when one of its deliveries settles" do
    admin_user = create(:admin_user)
    announcement = create(:announcement)
    delivery = announcement.delivery_for(:discord)
    delivery.save!

    payloads = assert_asyncapi_broadcast(params: {admin_user_gid: admin_user.to_gid_param}) do
      delivery.succeed!(external_id: "1234")
    end

    discord = payloads.first["deliveries"].find { |entry| entry["channel"] == "discord" }

    assert_equal "succeeded", discord["status"]
    assert_equal "1234", discord["externalId"]
  end
end
