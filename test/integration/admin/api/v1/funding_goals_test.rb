# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::FundingGoalsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/funding-goals" do
    post("Create Funding Goal") do
      operationId "createFundingGoal"
      tags "FundingGoals"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/FundingGoalInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FundingGoal"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end

    get("Funding Goals list") do
      operationId "fundingGoals"
      tags "FundingGoals"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: FundingGoal.default_per_page}, required: false
      parameter "$ref": "#/components/parameters/SortingParameter"
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/FundingGoalQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FundingGoals"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  api_path "/funding-goals/{id}" do
    parameter name: "id", in: :path, description: "Funding Goal id", schema: {type: :string, format: :uuid}

    delete("Destroy Funding Goal") do
      operationId "destroyFundingGoal"
      tags "FundingGoals"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FundingGoal"
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

    get("Funding Goal Detail") do
      operationId "fundingGoal"
      tags "FundingGoals"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FundingGoal"
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

    put("Update Funding Goal") do
      operationId "updateFundingGoal"
      tags "FundingGoals"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/FundingGoalInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FundingGoal"
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

  test "POST /funding-goals creates a funding goal" do
    sign_in @user

    body = {title: "Server costs", amountCents: 25_000, effectiveFrom: Date.current.iso8601}

    assert_api_response :post, 200, body: body do
      assert_equal "Server costs", parsed_body["title"]
      assert_equal 25_000, parsed_body["amountCents"]
      assert_equal "EUR", parsed_body["currency"]
    end
  end

  test "POST /funding-goals returns 401 when not signed in" do
    assert_api_response :post, 401, body: {title: "Test", amountCents: 100, effectiveFrom: Date.current.iso8601}
  end

  test "POST /funding-goals returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :post, 403, body: {title: "Test", amountCents: 100, effectiveFrom: Date.current.iso8601}
  end

  test "GET /funding-goals lists funding goals" do
    create_list(:funding_goal, 3)
    sign_in @user

    assert_api_response :get, 200 do
      assert_equal 3, parsed_body["items"].count
    end
  end

  test "GET /funding-goals returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /funding-goals returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end

  test "DELETE /funding-goals/:id destroys the funding goal" do
    funding_goal = create(:funding_goal)
    sign_in @user

    assert_api_response :delete, 200, path_params: {id: funding_goal.id}
  end

  test "DELETE /funding-goals/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :delete, 404, path_params: {id: SecureRandom.uuid}
  end

  test "DELETE /funding-goals/:id returns 401 when not signed in" do
    funding_goal = create(:funding_goal)

    assert_api_response :delete, 401, path_params: {id: funding_goal.id}
  end

  test "DELETE /funding-goals/:id returns 403 for admin without access" do
    funding_goal = create(:funding_goal)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :delete, 403, path_params: {id: funding_goal.id}
  end

  test "GET /funding-goals/:id returns the funding goal" do
    funding_goal = create(:funding_goal)
    sign_in @user

    assert_api_response :get, 200, path_params: {id: funding_goal.id}
  end

  test "GET /funding-goals/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :get, 404, path_params: {id: SecureRandom.uuid}
  end

  test "GET /funding-goals/:id returns 401 when not signed in" do
    funding_goal = create(:funding_goal)

    assert_api_response :get, 401, path_params: {id: funding_goal.id}
  end

  test "GET /funding-goals/:id returns 403 for admin without access" do
    funding_goal = create(:funding_goal)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, path_params: {id: funding_goal.id}
  end

  test "PUT /funding-goals/:id updates the funding goal" do
    funding_goal = create(:funding_goal, amount_cents: 5_000)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: funding_goal.id}, body: {title: "Updated", amountCents: 12_000, effectiveFrom: Date.current.iso8601} do
      assert_equal "Updated", parsed_body["title"]
      assert_equal 12_000, parsed_body["amountCents"]
    end
  end

  test "PUT /funding-goals/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :put, 404, path_params: {id: SecureRandom.uuid}, body: {title: "Test", amountCents: 100, effectiveFrom: Date.current.iso8601}
  end

  test "PUT /funding-goals/:id returns 401 when not signed in" do
    funding_goal = create(:funding_goal)

    assert_api_response :put, 401, path_params: {id: funding_goal.id}, body: {title: "Test", amountCents: 100, effectiveFrom: Date.current.iso8601}
  end

  test "PUT /funding-goals/:id returns 403 for admin without access" do
    funding_goal = create(:funding_goal)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, path_params: {id: funding_goal.id}, body: {title: "Test", amountCents: 100, effectiveFrom: Date.current.iso8601}
  end
end
