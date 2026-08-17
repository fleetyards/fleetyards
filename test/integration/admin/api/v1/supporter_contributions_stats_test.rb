# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::SupporterContributionsStatsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/supporter-contributions/stats" do
    get("Supporter Contributions Stats") do
      operationId "supporterContributionsStats"
      tags "SupporterContributions"
      produces "application/json"

      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/SupporterContributionQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/SupporterContributionStats"
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

  test "GET /supporter-contributions/stats returns aggregated stats" do
    create(:supporter_contribution, amount_cents: 500)
    create(:supporter_contribution, :recurring, amount_cents: 1_000)
    create(:supporter_contribution, :anonymous, amount_cents: 250)
    sign_in @user

    assert_api_response :get, 200 do
      assert_equal 1_750, parsed_body["totalAmountCents"]
      assert_equal 3, parsed_body["totalCount"]
      assert_equal 1, parsed_body["recurringCount"]
      assert_equal 1, parsed_body["anonymousCount"]
      assert_equal false, parsed_body["patreonSyncEnabled"]
    end
  end

  test "GET /supporter-contributions/stats respects ransack filters" do
    create(:supporter_contribution, amount_cents: 500)
    create(:supporter_contribution, :recurring, amount_cents: 1_000)
    sign_in @user

    assert_api_response :get, 200, params: {q: {"recurringEq" => true}} do
      assert_equal 1_000, parsed_body["totalAmountCents"]
      assert_equal 1, parsed_body["totalCount"]
    end
  end

  test "GET /supporter-contributions/stats returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /supporter-contributions/stats returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end
end
