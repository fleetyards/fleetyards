# frozen_string_literal: true

require "asyncapi_helper"

class AdminModelMediaChannelTest < AsyncapiTestCase
  asyncapi_schema "cable/admin/v1/schema"

  channel "admin_model_media:{admin_user_gid}", channel_class: AdminModelMediaChannel do
    parameter :admin_user_gid,
      description: "GlobalID param of the subscribed admin user, derived from the connection",
      client_supplied: false

    broadcast "A background crop of one of a model's views settled" do
      operationId "receiveAdminModelMedia"
      message ::Admin::V1::Schemas::Models::ModelMediaProcessing
    end
  end

  test "broadcasts the views still pending when a crop settles" do
    admin_user = create(:admin_user, resource_access: [:models])
    model = create(:model)
    model.update_columns(pending_trims: %w[top_view side_view].index_with { Time.current.iso8601(6) })

    payloads = assert_asyncapi_broadcast(params: {admin_user_gid: admin_user.to_gid_param}) do
      model.settle_trim("top_view")
    end

    assert_equal({"modelId" => model.id, "mediaProcessing" => ["sideView"]}, payloads.first)
  end
end
