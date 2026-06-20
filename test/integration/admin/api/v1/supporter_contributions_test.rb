# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::SupporterContributionsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/supporter-contributions" do
    post("Create Supporter Contribution") do
      operationId "createSupporterContribution"
      tags "SupporterContributions"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/SupporterContributionInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/SupporterContribution"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end

    get("Supporter Contributions list") do
      operationId "supporterContributions"
      tags "SupporterContributions"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: SupporterContribution.default_per_page}, required: false
      parameter "$ref": "#/components/parameters/SortingParameter"
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/SupporterContributionQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/SupporterContributions"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  api_path "/supporter-contributions/{id}" do
    parameter name: "id", in: :path, description: "Supporter Contribution id", schema: {type: :string, format: :uuid}

    delete("Destroy Supporter Contribution") do
      operationId "destroySupporterContribution"
      tags "SupporterContributions"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/SupporterContribution"
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end

    get("Supporter Contribution Detail") do
      operationId "supporterContribution"
      tags "SupporterContributions"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/SupporterContribution"
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end

    put("Update Supporter Contribution") do
      operationId "updateSupporterContribution"
      tags "SupporterContributions"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/SupporterContributionInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/SupporterContribution"
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
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

  test "POST /supporter-contributions creates a contribution" do
    sign_in @user

    body = {name: "Test Supporter", amountCents: 500, startedAt: Date.current.iso8601}

    assert_api_response :post, 200, body: body do
      assert_equal "Test Supporter", parsed_body["name"]
      assert_equal 500, parsed_body["amountCents"]
      assert_equal false, parsed_body["anonymous"]
      assert_equal false, parsed_body["recurring"]
    end
  end

  test "POST /supporter-contributions returns 401 when not signed in" do
    assert_api_response :post, 401, body: {amountCents: 100, startedAt: Date.current.iso8601}
  end

  test "POST /supporter-contributions returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :post, 403, body: {amountCents: 100, startedAt: Date.current.iso8601}
  end

  test "GET /supporter-contributions lists contributions" do
    create_list(:supporter_contribution, 3)
    sign_in @user

    assert_api_response :get, 200 do
      assert_equal 3, parsed_body["items"].count
    end
  end

  test "GET /supporter-contributions filters by recurringEq" do
    create_list(:supporter_contribution, 2)
    create_list(:supporter_contribution, 3, :recurring)
    sign_in @user

    assert_api_response :get, 200, params: {q: {"recurringEq" => true}} do
      assert_equal 3, parsed_body["items"].count
    end
  end

  test "GET /supporter-contributions returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /supporter-contributions returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end

  test "DELETE /supporter-contributions/:id destroys the contribution" do
    contribution = create(:supporter_contribution)
    sign_in @user

    assert_api_response :delete, 200, path_params: {id: contribution.id}
  end

  test "DELETE /supporter-contributions/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :delete, 404, path_params: {id: SecureRandom.uuid}
  end

  test "DELETE /supporter-contributions/:id returns 401 when not signed in" do
    contribution = create(:supporter_contribution)

    assert_api_response :delete, 401, path_params: {id: contribution.id}
  end

  test "DELETE /supporter-contributions/:id returns 403 for admin without access" do
    contribution = create(:supporter_contribution)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :delete, 403, path_params: {id: contribution.id}
  end

  test "GET /supporter-contributions/:id returns the contribution" do
    contribution = create(:supporter_contribution)
    sign_in @user

    assert_api_response :get, 200, path_params: {id: contribution.id}
  end

  test "GET /supporter-contributions/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :get, 404, path_params: {id: SecureRandom.uuid}
  end

  test "GET /supporter-contributions/:id returns 401 when not signed in" do
    contribution = create(:supporter_contribution)

    assert_api_response :get, 401, path_params: {id: contribution.id}
  end

  test "GET /supporter-contributions/:id returns 403 for admin without access" do
    contribution = create(:supporter_contribution)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, path_params: {id: contribution.id}
  end

  test "PUT /supporter-contributions/:id updates the contribution" do
    contribution = create(:supporter_contribution)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: contribution.id}, body: {name: "Updated Name", amountCents: 999, startedAt: Date.current.iso8601} do
      assert_equal "Updated Name", parsed_body["name"]
    end
  end

  test "PUT /supporter-contributions/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :put, 404, path_params: {id: SecureRandom.uuid}, body: {amountCents: 100, startedAt: Date.current.iso8601}
  end

  test "PUT /supporter-contributions/:id returns 401 when not signed in" do
    contribution = create(:supporter_contribution)

    assert_api_response :put, 401, path_params: {id: contribution.id}, body: {amountCents: 100, startedAt: Date.current.iso8601}
  end

  test "PUT /supporter-contributions/:id returns 403 for admin without access" do
    contribution = create(:supporter_contribution)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, path_params: {id: contribution.id}, body: {amountCents: 100, startedAt: Date.current.iso8601}
  end
end
