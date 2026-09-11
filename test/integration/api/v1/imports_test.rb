# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ImportsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/imports" do
    get("List your own imports") do
      operationId "imports"
      tags "Imports"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:read"]},
        {OpenId: ["hangar", "hangar:read"]}
      ]

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {
        type: :string, default: Import.default_per_page
      }, required: false
      parameter name: "q", in: :query,
        schema: ::V1::Schemas::Queries::ImportQuery,
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema ::V1::Schemas::Imports
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/imports/{id}" do
    parameter name: "id", in: :path, schema: {type: :string}, required: true

    get("Show one of your imports") do
      operationId "import"
      tags "Imports"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:read"]},
        {OpenId: ["hangar", "hangar:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Import
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/imports/{id}/cancel" do
    parameter name: "id", in: :path, schema: {type: :string}, required: true

    put("Cancel a running import") do
      operationId "cancelImport"
      tags "Imports"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Import
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  def create_import(user, state: "created", group: nil)
    import = Imports::HangarSync.create!(user_id: user.id, input: [], hangar_group_id: group&.id)
    import.update!(aasm_state: state)
    import
  end

  test "GET /imports lists the caller's imports" do
    user = create(:user)
    create_import(user)
    sign_in user

    assert_api_response :get, 200
  end

  test "GET /imports does not list somebody else's imports" do
    user = create(:user)
    create_import(create(:user))
    sign_in user

    assert_api_response :get, 200 do
      assert_empty parsed_body["items"]
    end
  end

  # Every other subclass is system- or admin-owned and carries no `user_id`, so
  # the owner scope is what keeps them out rather than a type list.
  test "GET /imports does not list system imports" do
    user = create(:user)
    Imports::PaintsImport.create!
    sign_in user

    assert_api_response :get, 200 do
      assert_empty parsed_body["items"]
    end
  end

  test "GET /imports renders the target group" do
    user = create(:user)
    group = HangarGroup.create!(user_id: user.id, name: "RSI", color: "#ffffff")
    create_import(user, group:)
    sign_in user

    assert_api_response :get, 200 do
      assert_equal "RSI", parsed_body["items"].first["hangarGroup"]["name"]
    end
  end

  test "GET /imports returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /imports/{id} shows the caller's import" do
    user = create(:user)
    import = create_import(user)
    sign_in user

    assert_api_response :get, 200, params: {id: import.id} do
      assert_equal import.id, parsed_body["id"]
    end
  end

  test "GET /imports/{id} returns 404 for somebody else's import" do
    user = create(:user)
    import = create_import(create(:user))
    sign_in user

    assert_api_response :get, 404, params: {id: import.id}
  end

  test "GET /imports/{id} returns 401 when not signed in" do
    import = create_import(create(:user))

    assert_api_response :get, 401, params: {id: import.id}
  end

  test "PUT /imports/{id}/cancel cancels a running import" do
    user = create(:user)
    import = create_import(user, state: "started")
    sign_in user

    assert_api_response :put, 200, params: {id: import.id} do
      assert_equal "cancelled", parsed_body["status"]
    end

    assert_predicate import.reload, :cancelled?
    assert_not_nil import.cancel_requested_at
  end

  test "PUT /imports/{id}/cancel cancels one that has not started yet" do
    user = create(:user)
    import = create_import(user)
    sign_in user

    assert_api_response :put, 200, params: {id: import.id}

    assert_predicate import.reload, :cancelled?
  end

  test "PUT /imports/{id}/cancel returns 400 for a finished import" do
    user = create(:user)
    import = create_import(user, state: "finished")
    sign_in user

    assert_api_response :put, 400, params: {id: import.id}
  end

  test "PUT /imports/{id}/cancel returns 404 for somebody else's import" do
    user = create(:user)
    import = create_import(create(:user), state: "started")
    sign_in user

    assert_api_response :put, 404, params: {id: import.id}
  end

  test "PUT /imports/{id}/cancel returns 401 when not signed in" do
    import = create_import(create(:user), state: "started")

    assert_api_response :put, 401, params: {id: import.id}
  end

  test "PUT /imports/{id}/cancel with OAuth bearer token" do
    user = create(:user)
    import = create_import(user, state: "started")

    assert_api_response :put, 200,
      params: {id: import.id},
      headers: oauth_headers_for(user, scopes: ["hangar", "hangar:write"])
  end
end
