# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::SupporterContributionsBulkTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/supporter-contributions/update-bulk" do
    put("Update Supporter Contributions in bulk") do
      operationId "updateSupporterContributionsBulk"
      tags "SupporterContributions"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::Admin::V1::Schemas::Inputs::SupporterContributionUpdateBulkInput

      response(200, "successful") do
        schema ::Admin::V1::Schemas::SupporterContributionBulkResult
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
  end

  api_path "/supporter-contributions/destroy-bulk" do
    put("Destroy Supporter Contributions in bulk") do
      operationId "destroySupporterContributionsBulk"
      tags "SupporterContributions"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::Admin::V1::Schemas::Inputs::SupporterContributionDestroyBulkInput

      response(200, "successful") do
        schema ::Admin::V1::Schemas::SupporterContributionBulkResult
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
    @user = create(:admin_user, resource_access: [:supporters])
  end

  test "PUT /supporter-contributions/update-bulk marks the selected contributions anonymous" do
    selected = create_list(:supporter_contribution, 2, name: "Named", anonymous: false)
    untouched = create(:supporter_contribution, name: "Named", anonymous: false)
    sign_in @user

    body = {ids: selected.map(&:id), anonymous: true}
    assert_api_response :put, 200, api_path: "/supporter-contributions/update-bulk", body: body do
      assert_equal 2, parsed_body["count"]
    end

    assert(selected.all? { |contribution| contribution.reload.anonymous? })
    assert_not untouched.reload.anonymous?
  end

  test "PUT /supporter-contributions/update-bulk files a version under the admin" do
    contribution = create(:supporter_contribution, name: "Named", anonymous: false)
    sign_in @user

    assert_difference -> { contribution.versions.count }, 1 do
      assert_api_response :put, 200, api_path: "/supporter-contributions/update-bulk",
        body: {ids: [contribution.id], anonymous: true}
    end

    assert_equal @user.id, contribution.versions.last.author_id
  end

  # A row without a name has nothing to show publicly, so the model keeps it
  # anonymous; the count says how many actually changed.
  test "PUT /supporter-contributions/update-bulk counts only the rows it changed" do
    named = create(:supporter_contribution, name: "Named", anonymous: true)
    nameless = create(:supporter_contribution, name: nil, anonymous: true)
    sign_in @user

    body = {ids: [named.id, nameless.id], anonymous: false}
    assert_api_response :put, 200, api_path: "/supporter-contributions/update-bulk", body: body do
      assert_equal 1, parsed_body["count"]
    end

    assert_not named.reload.anonymous?
    assert_predicate nameless.reload, :anonymous?
  end

  test "PUT /supporter-contributions/update-bulk sets the source of the selected contributions" do
    selected = create_list(:supporter_contribution, 2)
    untouched = create(:supporter_contribution)
    sign_in @user

    body = {ids: selected.map(&:id), source: "paypal"}
    assert_api_response :put, 200, api_path: "/supporter-contributions/update-bulk", body: body do
      assert_equal 2, parsed_body["count"]
    end

    assert_equal %w[paypal paypal], selected.map { |contribution| contribution.reload.source }
    assert_nil untouched.reload.source
  end

  test "PUT /supporter-contributions/update-bulk clears the source when given null" do
    contribution = create(:supporter_contribution, source: "other", anonymous: false)
    sign_in @user

    assert_api_response :put, 200, api_path: "/supporter-contributions/update-bulk",
      body: {ids: [contribution.id], source: nil} do
      assert_equal 1, parsed_body["count"]
    end

    assert_nil contribution.reload.source
    assert_not contribution.anonymous?
  end

  test "PUT /supporter-contributions/update-bulk leaves attributes it was not given alone" do
    contribution = create(:supporter_contribution, name: "Named", source: "kofi", anonymous: false)
    sign_in @user

    assert_api_response :put, 200, api_path: "/supporter-contributions/update-bulk",
      body: {ids: [contribution.id], anonymous: true}

    assert_equal "kofi", contribution.reload.source
  end

  test "PUT /supporter-contributions/update-bulk returns 401 when not signed in" do
    assert_api_response :put, 401, api_path: "/supporter-contributions/update-bulk",
      body: {ids: [], anonymous: true}
  end

  test "PUT /supporter-contributions/update-bulk returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, api_path: "/supporter-contributions/update-bulk",
      body: {ids: [], anonymous: true}
  end

  test "PUT /supporter-contributions/destroy-bulk deletes the selected contributions" do
    selected = create_list(:supporter_contribution, 2)
    untouched = create(:supporter_contribution)
    sign_in @user

    assert_api_response :put, 200, api_path: "/supporter-contributions/destroy-bulk",
      body: {ids: selected.map(&:id)} do
      assert_equal 2, parsed_body["count"]
    end

    assert_equal [untouched.id], SupporterContribution.pluck(:id)
  end

  test "PUT /supporter-contributions/destroy-bulk returns 401 when not signed in" do
    assert_api_response :put, 401, api_path: "/supporter-contributions/destroy-bulk", body: {ids: []}
  end

  test "PUT /supporter-contributions/destroy-bulk returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, api_path: "/supporter-contributions/destroy-bulk", body: {ids: []}
  end
end
