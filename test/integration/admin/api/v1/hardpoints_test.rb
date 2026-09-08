# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::HardpointsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  setup do
    @admin_user = create(:admin_user, resource_access: [:models])
    @model = create(:model)
    sign_in @admin_user
  end

  api_path "/hardpoints" do
    get("Hardpoints") do
      operationId "listHardpoints"
      tags "Hardpoints"
      produces "application/json"

      parameter name: "q", in: :query, schema: ::Admin::V1::Schemas::Queries::AdminHardpointQuery,
        required: false, style: :deepObject, explode: true

      response(200, "successful") do
        schema ::Admin::V1::Schemas::AdminHardpoints
      end
    end

    post("Create Hardpoint") do
      operationId "createHardpoint"
      tags "Hardpoints"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::Admin::V1::Schemas::Inputs::AdminHardpointInput

      response(201, "created") do
        schema ::Admin::V1::Schemas::AdminHardpoint
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
      end
    end
  end

  api_path "/hardpoints/{id}" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, required: true

    get("Hardpoint") do
      operationId "hardpoint"
      tags "Hardpoints"
      produces "application/json"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::AdminHardpoint
      end
    end

    put("Update Hardpoint") do
      operationId "updateHardpoint"
      tags "Hardpoints"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::Admin::V1::Schemas::Inputs::AdminHardpointInput

      response(200, "successful") do
        schema ::Admin::V1::Schemas::AdminHardpoint
      end
    end

    delete("Destroy Hardpoint") do
      operationId "destroyHardpoint"
      tags "Hardpoints"

      response(204, "no content") do
        schema nil
      end
    end
  end

  # --- Reading ---------------------------------------------------------------

  test "GET /hardpoints lists both halves of the table" do
    create(:hardpoint, parent: @model, sc_name: "from_the_files", source: :game_files)
    create(:hardpoint, :without_build, parent: @model, sc_name: "curated", source: :ship_matrix)

    assert_api_response :get, 200 do
      assert_equal ["curated", "from_the_files"], parsed_body["items"].map { |item| item["name"] }.sort
    end
  end

  # The whole point of the split: the frontend has to know which slots it may
  # offer for editing, and the rule lives here rather than being derived from
  # `source` in the client.
  test "GET /hardpoints says which slots an admin may change" do
    create(:hardpoint, parent: @model, sc_name: "from_the_files", source: :game_files)
    create(:hardpoint, :without_build, parent: @model, sc_name: "curated", source: :ship_matrix)

    assert_api_response :get, 200 do
      editable = parsed_body["items"].to_h { |item| [item["name"], item["editable"]] }

      assert_equal false, editable["from_the_files"]
      assert_equal true, editable["curated"]
    end
  end

  # A loadout is a tree, so the nested slots come with their parent rather than
  # as their own rows in the page.
  test "GET /hardpoints nests the children under their slot" do
    parent = create(:hardpoint, parent: @model, sc_name: "turret", source: :game_files)
    create(:hardpoint, parent:, sc_name: "gun", source: :game_files)

    assert_api_response :get, 200 do
      assert_equal ["turret"], parsed_body["items"].map { |item| item["name"] }
      assert_equal ["gun"], parsed_body["items"].sole["hardpoints"].map { |child| child["name"] }
    end
  end

  test "GET /hardpoints/{id} returns one slot" do
    hardpoint = create(:hardpoint, parent: @model, source: :game_files)

    assert_api_response :get, 200, path_params: {id: hardpoint.id}
  end

  # --- Writing ---------------------------------------------------------------

  # `persist_loadout` scopes its cleanup to `game_files` so a load cannot reach
  # hand-entered data, which is what makes the matrix half an admin's to own.
  test "PUT /hardpoints/{id} changes a curated slot" do
    hardpoint = create(:hardpoint, :without_build, parent: @model, source: :ship_matrix)

    assert_api_response :put, 200, path_params: {id: hardpoint.id}, body: {scName: "renamed"}

    assert_equal "renamed", hardpoint.reload.sc_name
  end

  # The loader owns the other half: `persist_slot` rewrites those rows on every
  # load, so an edit would last until the next one and then vanish without a
  # word. That is what made the legacy editor pointless, and refusing is more
  # honest than accepting.
  test "PUT /hardpoints/{id} refuses a slot the loader owns" do
    hardpoint = create(:hardpoint, parent: @model, sc_name: "from_the_files", source: :game_files)

    put "/admin/api/v1/hardpoints/#{hardpoint.id}", params: {scName: "renamed"}, as: :json

    assert_response :forbidden
    assert_equal "from_the_files", hardpoint.reload.sc_name
  end

  test "DELETE /hardpoints/{id} removes a curated slot" do
    hardpoint = create(:hardpoint, :without_build, parent: @model, source: :ship_matrix)

    assert_api_response :delete, 204, path_params: {id: hardpoint.id}

    assert_not Hardpoint.exists?(hardpoint.id)
  end

  test "DELETE /hardpoints/{id} refuses a slot the loader owns" do
    hardpoint = create(:hardpoint, parent: @model, source: :game_files)

    delete "/admin/api/v1/hardpoints/#{hardpoint.id}", as: :json

    assert_response :forbidden
    assert Hardpoint.exists?(hardpoint.id)
  end

  # Created as `ship_matrix` whatever the request says, so there is no way to
  # ask for a game-files row the next load would rewrite.
  test "POST /hardpoints creates a curated slot" do
    assert_api_response :post, 201,
      body: {parentId: @model.id, parentType: "Model", scName: "hand_made"}

    hardpoint = Hardpoint.find_by(sc_name: "hand_made")
    assert_equal "ship_matrix", hardpoint.source
    assert_equal true, parsed_body["editable"]
  end
end
