# frozen_string_literal: true

require "openapi_helper"
require "discord/announcement_preview"

class Admin::Api::V1::AnnouncementsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/announcements" do
    post("Create Announcement") do
      operationId "createAnnouncement"
      tags "Announcements"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::Admin::V1::Schemas::Inputs::AnnouncementInput

      response(201, "created") do
        schema ::Admin::V1::Schemas::Announcement
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end

    get("Announcements list") do
      operationId "announcements"
      tags "Announcements"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: Announcement.default_per_page}, required: false
      parameter "$ref": "#/components/parameters/SortingParameter"
      parameter name: "q", in: :query,
        schema: ::Admin::V1::Schemas::Queries::AnnouncementQuery,
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema ::Admin::V1::Schemas::Announcements
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/announcements/{id}" do
    parameter name: "id", in: :path, description: "Announcement id", schema: {type: :string, format: :uuid}

    get("Announcement Detail") do
      operationId "announcement"
      tags "Announcements"
      produces "application/json"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::Announcement
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end

    put("Update Announcement") do
      operationId "updateAnnouncement"
      tags "Announcements"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::Admin::V1::Schemas::Inputs::AnnouncementInput

      response(200, "successful") do
        schema ::Admin::V1::Schemas::Announcement
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end

    delete("Destroy Announcement") do
      operationId "destroyAnnouncement"
      tags "Announcements"
      produces "application/json"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::Announcement
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/announcements/{id}/publish" do
    parameter name: "id", in: :path, description: "Announcement id", schema: {type: :string, format: :uuid}

    put("Publish Announcement") do
      operationId "publishAnnouncement"
      tags "Announcements"
      produces "application/json"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::Announcement
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/announcements/{id}/send-test" do
    parameter name: "id", in: :path, description: "Announcement id", schema: {type: :string, format: :uuid}

    put("Send Announcement Test") do
      operationId "sendAnnouncementTest"
      tags "Announcements"
      produces "application/json"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::Announcement
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/announcements/{id}/deliveries/{channel}/retry" do
    parameter name: "id", in: :path, description: "Announcement id", schema: {type: :string, format: :uuid}
    parameter name: "channel", in: :path, description: "Delivery channel",
      schema: ::Admin::V1::Schemas::Enums::AnnouncementChannelEnum

    put("Retry Announcement Delivery") do
      operationId "retryAnnouncementDelivery"
      tags "Announcements"
      produces "application/json"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::Announcement
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @admin_user = create(:admin_user, resource_access: [:announcements])
  end

  test "POST /announcements creates a draft" do
    sign_in @admin_user

    body = {title: "Contracts", body: "Fleets can post jobs now.", postBluesky: true}

    assert_api_response :post, 201, body: body do
      assert_equal "Contracts", parsed_body["title"]
      assert_equal "draft", parsed_body["status"]
      assert parsed_body["publishable"]
      assert_equal @admin_user.username, parsed_body["author"]
    end
  end

  # The Fleet Ops beta copy is two Discord messages and a two-post thread, and
  # both lists have to survive the round trip in the order they were written.
  test "POST /announcements keeps the ordered Discord messages and social thread" do
    sign_in @admin_user

    body = {
      title: "Fleet Ops",
      body: "Four new tools for running a fleet.",
      discordParts: ["## Fleet Ops is in public beta", "**How to switch them on**"],
      socialParts: ["Fleet Ops is in public beta 🚀", "Free in beta, then supporter features."],
      postDiscord: true,
      postX: true
    }

    assert_api_response :post, 201, body: body do
      assert_equal ["## Fleet Ops is in public beta", "**How to switch them on**"], parsed_body["discordParts"]
      assert_equal 2, parsed_body["socialParts"].size
      assert_equal "Fleet Ops is in public beta 🚀", parsed_body["socialParts"].first
    end
  end

  test "POST /announcements refuses a social post past the platform limit" do
    sign_in @admin_user

    assert_api_response :post, 400, body: {title: "x", body: "y", socialParts: ["z" * 301]} do
      assert_equal "validation_error.announcement.create", parsed_body["code"]
    end
  end

  test "POST /announcements rejects an announcement with no channel" do
    sign_in @admin_user

    assert_api_response :post, 400, body: {title: "x", body: "y", notifyUsers: false}
  end

  test "POST /announcements returns 401 when not signed in" do
    assert_api_response :post, 401, body: {title: "x", body: "y"}
  end

  test "POST /announcements returns 403 for an admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :post, 403, body: {title: "x", body: "y"}
  end

  test "GET /announcements lists announcements" do
    create_list(:announcement, 3)
    sign_in @admin_user

    assert_api_response :get, 200 do
      assert_equal 3, parsed_body["items"].count
    end
  end

  test "GET /announcements returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /announcements returns 403 for an admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end

  test "GET /announcements/:id returns the announcement with its deliveries" do
    announcement = create(:announcement, :social)
    create(:announcement_delivery, announcement:, channel: "bluesky", status: "failed", error: "rate limited")
    sign_in @admin_user

    assert_api_response :get, 200, path_params: {id: announcement.id} do
      delivery = parsed_body["deliveries"].first

      assert_equal "bluesky", delivery["channel"]
      assert_equal "failed", delivery["status"]
      assert_equal "rate limited", delivery["error"]
    end
  end

  test "GET /announcements/:id returns 404 for a missing id" do
    sign_in @admin_user

    assert_api_response :get, 404, path_params: {id: SecureRandom.uuid}
  end

  test "GET /announcements/:id returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {id: create(:announcement).id}
  end

  test "GET /announcements/:id returns 403 for an admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, path_params: {id: create(:announcement).id}
  end

  test "PUT /announcements/:id updates a draft" do
    announcement = create(:announcement)
    sign_in @admin_user

    assert_api_response :put, 200, api_path: "/announcements/{id}", path_params: {id: announcement.id}, body: {title: "Updated", body: "New text.", postX: true} do
      assert_equal "Updated", parsed_body["title"]
      assert parsed_body["postX"]
    end
  end

  test "PUT /announcements/:id refuses to edit one that already went out" do
    announcement = create(:announcement, :published)
    sign_in @admin_user

    assert_api_response :put, 400, api_path: "/announcements/{id}", path_params: {id: announcement.id}, body: {title: "Updated", body: "New text."} do
      assert_equal "validation_error.announcement.already_published", parsed_body["code"]
    end
  end

  test "PUT /announcements/:id returns 404 for a missing id" do
    sign_in @admin_user

    assert_api_response :put, 404, api_path: "/announcements/{id}", path_params: {id: SecureRandom.uuid}, body: {title: "x", body: "y"}
  end

  test "PUT /announcements/:id returns 401 when not signed in" do
    assert_api_response :put, 401, api_path: "/announcements/{id}", path_params: {id: create(:announcement).id}, body: {title: "x", body: "y"}
  end

  test "PUT /announcements/:id returns 403 for an admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, api_path: "/announcements/{id}", path_params: {id: create(:announcement).id}, body: {title: "x", body: "y"}
  end

  test "DELETE /announcements/:id destroys the announcement" do
    announcement = create(:announcement)
    sign_in @admin_user

    assert_api_response :delete, 200, path_params: {id: announcement.id}

    refute Announcement.exists?(announcement.id)
  end

  test "DELETE /announcements/:id returns 404 for a missing id" do
    sign_in @admin_user

    assert_api_response :delete, 404, path_params: {id: SecureRandom.uuid}
  end

  test "DELETE /announcements/:id returns 401 when not signed in" do
    assert_api_response :delete, 401, path_params: {id: create(:announcement).id}
  end

  test "DELETE /announcements/:id returns 403 for an admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :delete, 403, path_params: {id: create(:announcement).id}
  end

  test "PUT /announcements/:id/publish queues the publish job" do
    announcement = create(:announcement)
    sign_in @admin_user

    Announcements::PublishJob.expects(:perform_async).with(announcement.id).once

    assert_api_response :put, 200, api_path: "/announcements/{id}/publish", path_params: {id: announcement.id}
  end

  test "PUT /announcements/:id/publish refuses one that already went out" do
    announcement = create(:announcement, :published)
    sign_in @admin_user

    Announcements::PublishJob.expects(:perform_async).never

    assert_api_response :put, 400, api_path: "/announcements/{id}/publish", path_params: {id: announcement.id}
  end

  test "PUT /announcements/:id/publish returns 404 for a missing id" do
    sign_in @admin_user

    assert_api_response :put, 404, api_path: "/announcements/{id}/publish", path_params: {id: SecureRandom.uuid}
  end

  test "PUT /announcements/:id/publish returns 401 when not signed in" do
    assert_api_response :put, 401, api_path: "/announcements/{id}/publish", path_params: {id: create(:announcement).id}
  end

  test "PUT /announcements/:id/publish returns 403 for an admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, api_path: "/announcements/{id}/publish", path_params: {id: create(:announcement).id}
  end

  test "PUT /announcements/:id/send-test queues the dry run without touching the announcement" do
    announcement = create(:announcement, :social)
    sign_in @admin_user
    ::Discord::AnnouncementPreview.stubs(:configured?).returns(true)

    Announcements::SendTestJob.expects(:perform_async).with(announcement.id).once

    assert_api_response :put, 200, api_path: "/announcements/{id}/send-test", path_params: {id: announcement.id} do
      assert_equal "draft", parsed_body["status"]
      assert_empty parsed_body["deliveries"]
    end
  end

  test "PUT /announcements/:id/send-test is offered on an announcement that already went out" do
    announcement = create(:announcement, :published)
    sign_in @admin_user
    ::Discord::AnnouncementPreview.stubs(:configured?).returns(true)

    Announcements::SendTestJob.expects(:perform_async).once

    assert_api_response :put, 200, api_path: "/announcements/{id}/send-test", path_params: {id: announcement.id}
  end

  test "PUT /announcements/:id/send-test says so when the admin channel has no webhook" do
    announcement = create(:announcement)
    sign_in @admin_user
    ::Discord::AnnouncementPreview.stubs(:configured?).returns(false)

    Announcements::SendTestJob.expects(:perform_async).never

    assert_api_response :put, 400, api_path: "/announcements/{id}/send-test", path_params: {id: announcement.id} do
      assert_equal "validation_error.announcement.test_not_configured", parsed_body["code"]
    end
  end

  test "PUT /announcements/:id/send-test returns 404 for a missing id" do
    sign_in @admin_user
    ::Discord::AnnouncementPreview.stubs(:configured?).returns(true)

    assert_api_response :put, 404, api_path: "/announcements/{id}/send-test", path_params: {id: SecureRandom.uuid}
  end

  test "PUT /announcements/:id/send-test returns 401 when not signed in" do
    assert_api_response :put, 401, api_path: "/announcements/{id}/send-test", path_params: {id: create(:announcement).id}
  end

  test "PUT /announcements/:id/send-test returns 403 for an admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, api_path: "/announcements/{id}/send-test", path_params: {id: create(:announcement).id}
  end

  test "PUT /announcements/:id/deliveries/:channel/retry re-queues a failed post" do
    announcement = create(:announcement, :social, :published)
    create(:announcement_delivery, announcement:, channel: "x", status: "failed", error: "rate limited")
    sign_in @admin_user

    Announcements::PostSocialJob.expects(:perform_async).with(announcement.id, "x").once

    assert_api_response :put, 200, path_params: {id: announcement.id, channel: "x"} do
      delivery = parsed_body["deliveries"].find { |row| row["channel"] == "x" }

      assert_equal "pending", delivery["status"]
    end
  end

  test "PUT /announcements/:id/deliveries/:channel/retry re-runs the fan-out for the in-app channel" do
    announcement = create(:announcement, :published)
    create(:announcement_delivery, announcement:, channel: "in_app", status: "failed")
    sign_in @admin_user

    Announcements::FanOutJob.expects(:perform_async).with(announcement.id).once

    assert_api_response :put, 200, path_params: {id: announcement.id, channel: "in_app"}
  end

  test "PUT /announcements/:id/deliveries/:channel/retry claims the delivery so a second click is refused" do
    announcement = create(:announcement, :social, :published)
    delivery = create(:announcement_delivery, announcement:, channel: "x", status: "failed")
    sign_in @admin_user

    Announcements::PostSocialJob.expects(:perform_async).once

    assert_api_response :put, 200, path_params: {id: announcement.id, channel: "x"}
    assert_api_response :put, 400, path_params: {id: announcement.id, channel: "x"}

    assert_equal "pending", delivery.reload.status
  end

  test "PUT /announcements/:id/deliveries/:channel/retry refuses a delivery that succeeded" do
    announcement = create(:announcement, :social, :published)
    create(:announcement_delivery, announcement:, channel: "x", status: "succeeded")
    sign_in @admin_user

    Announcements::PostSocialJob.expects(:perform_async).never

    assert_api_response :put, 400, path_params: {id: announcement.id, channel: "x"}
  end

  test "PUT /announcements/:id/deliveries/:channel/retry returns 404 for a channel that was never sent" do
    announcement = create(:announcement, :published)
    sign_in @admin_user

    assert_api_response :put, 404, path_params: {id: announcement.id, channel: "x"}
  end

  test "PUT /announcements/:id/deliveries/:channel/retry returns 401 when not signed in" do
    assert_api_response :put, 401, path_params: {id: create(:announcement).id, channel: "x"}
  end

  test "PUT /announcements/:id/deliveries/:channel/retry returns 403 for an admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, path_params: {id: create(:announcement).id, channel: "x"}
  end
end
