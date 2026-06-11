# frozen_string_literal: true

require_relative "../../../../openapi_helper"

class Admin::Api::V1::ComponentsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  # Operation order matches the alphabetical load order of the original
  # spec files (create, destroy, index, show, update).

  api_path "/components" do
    post("Create Component") do
      operationId "createComponent"
      tags "Components"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/ComponentInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Component"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end

    get("Components list") do
      operationId "components"
      tags "Components"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: Component.default_per_page}, required: false
      parameter "$ref": "#/components/parameters/SortingParameter"
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/ComponentQuery"
        },
        style: :deepObject,
        explode: true,
        required: false
      parameter name: "cacheId", in: :query, schema: {type: :string}, required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Components"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  api_path "/components/{id}" do
    parameter name: "id", in: :path, description: "Component id", schema: {type: :string, format: :uuid}, required: true

    delete("Destroy Component") do
      operationId "destroyComponent"
      tags "Components"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Component"
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

    get("Component Detail") do
      operationId "component"
      tags "Components"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Component"
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

    put("Update Component") do
      operationId "updateComponent"
      tags "Components"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/ComponentInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Component"
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
    @user = create(:admin_user, resource_access: [:components])
  end

  # POST /components
  test "POST /components creates a component" do
    sign_in @user

    assert_api_response :post, 200, body: {name: "Power Plant"} do
      assert_equal "Power Plant", parsed_body["name"]
    end
  end

  test "POST /components returns 401 when not signed in" do
    assert_api_response :post, 401, body: {name: "x"}
  end

  test "POST /components returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :post, 403, body: {name: "x"}
  end

  # GET /components
  test "GET /components lists components" do
    create_list(:component, 2)
    create(:component, name: "CF-227 Badger")
    sign_in @user

    assert_api_response :get, 200 do
      assert_equal 2, parsed_body.count
    end
  end

  test "GET /components filters by nameCont query" do
    create_list(:component, 2)
    create(:component, name: "CF-227 Badger")
    sign_in @user

    assert_api_response :get, 200, params: {q: {"nameCont" => "Badger"}} do
      items = parsed_body["items"]
      assert_equal 1, items.count
      assert_equal "CF-227 Badger", items.first["name"]
    end
  end

  test "GET /components paginates with perPage" do
    create_list(:component, 2)
    create(:component, name: "CF-227 Badger")
    sign_in @user

    assert_api_response :get, 200, params: {perPage: 2} do
      assert_equal 2, parsed_body.count
    end
  end

  test "GET /components returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /components returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end

  # DELETE /components/:id
  test "DELETE /components/:id destroys the component" do
    component = create(:component)
    sign_in @user

    assert_api_response :delete, 200, path_params: {id: component.id}
  end

  test "DELETE /components/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :delete, 404, path_params: {id: SecureRandom.uuid}
  end

  test "DELETE /components/:id returns 401 when not signed in" do
    component = create(:component)

    assert_api_response :delete, 401, path_params: {id: component.id}
  end

  test "DELETE /components/:id returns 403 for admin without access" do
    component = create(:component)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :delete, 403, path_params: {id: component.id}
  end

  # GET /components/:id
  test "GET /components/:id returns the component" do
    component = create(:component)
    sign_in @user

    assert_api_response :get, 200, path_params: {id: component.id}
  end

  test "GET /components/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :get, 404, path_params: {id: "5b30f7ab-5c62-4bec-9db7-e187f84f6aeb"}
  end

  test "GET /components/:id returns 401 when not signed in" do
    component = create(:component)

    assert_api_response :get, 401, path_params: {id: component.id}
  end

  test "GET /components/:id returns 403 for admin without access" do
    component = create(:component)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, path_params: {id: component.id}
  end

  # PUT /components/:id
  test "PUT /components/:id updates the component" do
    component = create(:component)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: component.id}, body: {name: "Updated Component"} do
      assert_equal "Updated Component", parsed_body["name"]
    end
  end

  test "PUT /components/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :put, 404, path_params: {id: SecureRandom.uuid}, body: {name: "x"}
  end

  test "PUT /components/:id returns 401 when not signed in" do
    component = create(:component)

    assert_api_response :put, 401, path_params: {id: component.id}, body: {name: "x"}
  end

  test "PUT /components/:id returns 403 for admin without access" do
    component = create(:component)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, path_params: {id: component.id}, body: {name: "x"}
  end
end
