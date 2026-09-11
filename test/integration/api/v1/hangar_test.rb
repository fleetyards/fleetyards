# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/hangar" do
    delete("Clear your personal Hangar") do
      operationId "destroyHangar"
      tags "Hangar"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(204, "successful")

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end

    get("Your personal Hangar") do
      operationId "hangar"
      tags "Hangar"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:read"]},
        {OpenId: ["hangar", "hangar:read"]}
      ]

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {
        type: :string, default: Vehicle.default_per_page
      }, required: false
      parameter name: "q", in: :query,
        schema: ::V1::Schemas::Queries::HangarQuery,
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema ::V1::Schemas::Hangar::Hangar
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  # A carrier holding a dock of each kind takes the branch that used to hand a
  # Hash to `or`, which Rails refuses outright -- so this filter answered with a
  # 500 for exactly the three ships anybody would pick: Polaris, Carrack, 890
  # Jump.
  test "GET /hangar filters by a carrier that takes both ships and vehicles" do
    user = create(:user)
    carrier = create(:model, slug: "carrier-with-both")
    create(:dock, :with_dimensions, parent: carrier, dock_type: :hangar)
    create(:dock, :with_dimensions, parent: carrier, dock_type: :garage)

    fits = create(:model, ground: false, length: 20.0, beam: 10.0, height: 5.0)
    too_big = create(:model, ground: false, length: 200.0, beam: 100.0, height: 50.0)
    create(:vehicle, user:, model: fits, wanted: false)
    create(:vehicle, user:, model: too_big, wanted: false)

    sign_in user

    assert_api_response :get, 200, params: {q: {willItFit: carrier.slug}} do
      slugs = parsed_body["items"].map { |item| item.dig("model", "slug") }

      assert_includes slugs, fits.slug
      assert_not_includes slugs, too_big.slug
    end
  end

  test "DELETE /hangar clears the hangar" do
    user = create(:user, vehicle_count: 2)
    sign_in user

    assert_api_response :delete, 204 do
      assert_equal 0, user.vehicles.where(wanted: false).count
    end
  end

  test "DELETE /hangar returns 401 when not signed in" do
    assert_api_response :delete, 401
  end

  test "GET /hangar returns the user's vehicles" do
    user = create(:user, vehicle_count: 3)
    sign_in user

    assert_api_response :get, 200 do
      assert_operator parsed_body["items"].count, :>, 0
    end
  end

  test "GET /hangar filters by query" do
    user = create(:user, vehicle_count: 3)
    sign_in user

    assert_api_response :get, 200, params: {q: {"modelNameOrModelDescriptionCont" => user.vehicles.first.model.name}} do
      assert_operator parsed_body["items"].count, :>=, 1
    end
  end

  test "GET /hangar honours sort orders" do
    user = create(:user, :with_rsi_handle)
    model_alpha = create(:model, name: "Alpha")
    model_bravo = create(:model, name: "Bravo")
    model_charlie = create(:model, :with_store_image, name: "Charlie")
    create(:vehicle, user: user, model: model_alpha)
    create(:vehicle, user: user, model: model_bravo)
    create(:vehicle, user: user, model: model_charlie)
    sign_in user

    assert_api_response :get, 200, params: {q: {"sorts" => "modelName asc"}} do
      names = parsed_body["items"].map { |m| m.dig("model", "name") }
      assert_equal %w[Alpha Bravo Charlie], names
    end
  end

  test "GET /hangar returns 400 for invalid query" do
    user = create(:user, vehicle_count: 1)
    sign_in user

    assert_api_response :get, 400, params: {q: {"foo" => "bar"}}
  end

  test "GET /hangar returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "DELETE /hangar with OAuth bearer token" do
    user = create(:user, vehicle_count: 2)

    assert_api_response :delete, 204, headers: oauth_headers_for(user, scopes: ["hangar", "hangar:write"])
  end

  test "GET /hangar with OAuth bearer token" do
    user = create(:user, vehicle_count: 3)

    assert_api_response :get, 200, headers: oauth_headers_for(user, scopes: ["hangar", "hangar:read"])
  end
end
