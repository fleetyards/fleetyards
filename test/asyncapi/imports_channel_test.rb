# frozen_string_literal: true

require "asyncapi_helper"

# Every Import subclass that keeps the base #notify_admin renders
# api/v1/imports/base, so the nine broadcasting types share one payload shape.
class ImportsChannelTest < AsyncapiTestCase
  asyncapi_schema "cable/admin/v1/schema"

  channel "imports:{admin_user_gid}", channel_class: ImportsChannel do
    parameter :admin_user_gid,
      description: "GlobalID param of the subscribed admin user, derived from the connection",
      client_supplied: false

    broadcast "An import changed state" do
      operationId "receiveImport"
      message ::Admin::V1::Schemas::Import
    end
  end

  test "broadcasts the import payload to admins" do
    admin_user = create(:admin_user)
    import = create(:import, :modules_import)

    payloads = assert_asyncapi_broadcast(params: {admin_user_gid: admin_user.to_gid_param}) do
      import.notify_admin
    end

    assert_equal import.id, payloads.first["id"]
  end
end
