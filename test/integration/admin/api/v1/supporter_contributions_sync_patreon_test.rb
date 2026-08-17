# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::SupporterContributionsSyncPatreonTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/supporter-contributions/sync-patreon" do
    post("Sync Supporter Contributions from Patreon") do
      operationId "syncSupporterContributionsFromPatreon"
      tags "SupporterContributions"
      produces "application/json"

      response(202, "accepted") do
        schema type: :object, properties: {message: {type: :string}}, required: [:message]
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    @user = create(:admin_user, resource_access: [:supporters])
  end

  test "POST /supporter-contributions/sync-patreon enqueues the sync job" do
    PatreonSupporterSyncJob.expects(:perform_async).once
    sign_in @user

    assert_api_response :post, 202, body: {}
  end

  test "POST /supporter-contributions/sync-patreon returns 401 when not signed in" do
    assert_api_response :post, 401, body: {}
  end

  test "POST /supporter-contributions/sync-patreon returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :post, 403, body: {}
  end
end
