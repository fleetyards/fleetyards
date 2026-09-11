# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::VersionsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/versions" do
    get("Versions list") do
      operationId "versions"
      tags "Versions"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string}, required: false
      parameter name: "itemType", in: :query, schema: ::Admin::V1::Schemas::Enums::VersionItemTypeEnum, required: true
      parameter name: "itemId", in: :query, schema: {type: :string, format: :uuid}, required: true

      response(200, "successful") do
        schema ::Admin::V1::Schemas::Versions
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/versions/{id}/revert" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "id"

    put("Revert one field of a version") do
      operationId "revertVersion"
      tags "Versions"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::Admin::V1::Schemas::Inputs::VersionRevertInput

      response(204, "successful") do
        schema nil
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
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
    @user = create(:admin_user, resource_access: [:models])
    @model = create(:model, name: "Carrack", cargo: 456)
    @model.update!(cargo: 400)
    @version = @model.versions.last
  end

  def list_params(item = nil)
    item ||= @model

    {itemType: item.class.name, itemId: item.id}
  end

  # GET list
  test "GET /versions lists the history of one item" do
    sign_in @user

    assert_api_response :get, 200, params: list_params do
      assert_equal 1, parsed_body["items"].count
      assert_equal [{"field" => "cargo", "from" => "456.0", "to" => "400.0"}], parsed_body["items"].first["changes"]
    end
  end

  # The touch versions paper_trail already filed have no `object_changes` at all,
  # so there is nothing to show for one -- it rendered as a heading with an empty
  # body. Fixing the recording does not remove the 572,735 already on disk.
  test "GET /versions skips a version that recorded no changes" do
    fleet = create(:fleet, created_by: create(:user).id)
    fleet.update!(description: "A crew")
    PaperTrail::Version.create!(item_type: "Fleet", item_id: fleet.id, event: "update", object_changes: nil)
    sign_in create(:admin_user, resource_access: [:fleets])

    assert_api_response :get, 200, params: list_params(fleet) do
      assert_equal 2, parsed_body["items"].count
      assert_empty parsed_body["items"].select { |version| version["changes"].empty? }
    end
  end

  test "GET /versions returns 404 for a missing id" do
    sign_in @user

    assert_api_response :get, 404, params: {itemType: "Model", itemId: "00000000-0000-0000-0000-000000000000"}
  end

  test "GET /versions returns 401 when not signed in" do
    assert_api_response :get, 401, params: list_params
  end

  test "GET /versions returns 403 for an admin without access to the item" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, params: list_params
  end

  # A fleet's roles and inventories have no admin page of their own, so the
  # fleet's access is what decides.
  test "GET /versions authorises a fleet role through its fleet" do
    role = create(:fleet_role, name: "Quartermaster")
    role.update!(name: "Bosun")
    sign_in create(:admin_user, resource_access: [:fleets])

    assert_api_response :get, 200, params: list_params(role) do
      assert_equal role.versions.count, parsed_body["items"].count
    end
  end

  test "GET /versions returns 403 for a fleet role without fleet access" do
    role = create(:fleet_role, name: "Quartermaster")
    role.update!(name: "Bosun")
    sign_in @user

    assert_api_response :get, 403, params: list_params(role)
  end

  # PUT revert
  test "PUT /versions/:id/revert puts one field back" do
    sign_in @user

    assert_api_response :put, 204, path_params: {id: @version.id}, body: {field: "cargo"} do
      assert_equal 456, @model.reload.cargo
    end
  end

  test "PUT /versions/:id/revert records who reverted it and why" do
    sign_in @user

    assert_api_response :put, 204, path_params: {id: @version.id}, body: {field: "cargo"} do
      reverting = @model.reload.versions.last

      assert_equal @user.id, reverting.author_id
      assert_equal "custom", reverting.reason
      assert_equal "Reverted cargo", reverting.reason_description
    end
  end

  test "PUT /versions/:id/revert returns 400 for a field the version never changed" do
    sign_in @user

    assert_api_response :put, 400, path_params: {id: @version.id}, body: {field: "mass"}
  end

  test "PUT /versions/:id/revert returns 400 when the value is already back" do
    @model.update!(cargo: 456)
    sign_in @user

    assert_api_response :put, 400, path_params: {id: @version.id}, body: {field: "cargo"}
  end

  # Six of the ten track creates too, and a create's changeset is every column
  # from nothing -- there is no previous value to go back to.
  test "PUT /versions/:id/revert returns 400 for a create version" do
    role = create(:fleet_role, name: "Quartermaster")
    creation = role.versions.find_by(event: "create")
    sign_in create(:admin_user, resource_access: [:fleets])

    assert_api_response :put, 400, path_params: {id: creation.id}, body: {field: "name"}
  end

  # Reverting `name` on an entry that shares its position would move that one
  # entry out, stranding the rest -- the ledger refuses it, so the reverter
  # reports it. Renaming a whole position no longer files a version on the
  # entries at all, so the version this needs is the one a single-entry
  # correction leaves behind, made while the entry was still alone.
  test "PUT /versions/:id/revert returns 400 for a name another entry shares" do
    entry, = renamed_then_shared
    version = entry.versions.where(event: "update").last
    sign_in create(:admin_user, resource_access: [:users])

    assert_api_response :put, 400, path_params: {id: version.id}, body: {field: "name"} do
      assert_includes parsed_body["errors"].to_s, "update the whole position instead"
      assert_equal "Quantanium", entry.reload.name
    end
  end

  # An entry alone in its position is the whole position, so putting its name
  # back moves nothing out of anything.
  test "PUT /versions/:id/revert reverts a name no other entry shares" do
    entry = create(:inventory_item, name: "Quantaniumm", category: :commodity, unit: :scu, quantity: 100)
    entry.update!(name: "Quantanium")
    sign_in create(:admin_user, resource_access: [:users])

    assert_api_response :put, 204, path_params: {id: entry.versions.last.id}, body: {field: "name"} do
      assert_equal "Quantaniumm", entry.reload.name
    end
  end

  test "PUT /versions/:id/revert still reverts a field the position does not share" do
    entry, = renamed_then_shared
    entry.update!(notes: "Second run")
    sign_in create(:admin_user, resource_access: [:users])

    assert_api_response :put, 204,
      path_params: {id: entry.versions.where(event: "update").last.id}, body: {field: "notes"} do
      assert_nil entry.reload.notes
    end
  end

  # An entry renamed while it was the only one in its position -- which files an
  # `update` version carrying `name` -- and then joined by a second entry, so
  # the name it would be reverted to is one it now shares.
  def renamed_then_shared
    inventory = create(:inventory)
    entry = create(:inventory_item, inventory:, name: "Quantaniumm", category: :commodity, unit: :scu, quantity: 100)
    entry.update!(name: "Quantanium")
    sibling = create(:inventory_item, :withdrawal, inventory:, name: "Quantanium",
      category: :commodity, unit: :scu, quantity: 30)

    [entry, sibling]
  end

  test "PUT /versions/:id/revert returns 404 for a missing id" do
    sign_in @user

    assert_api_response :put, 404, path_params: {id: "00000000-0000-0000-0000-000000000000"}, body: {field: "cargo"}
  end

  test "PUT /versions/:id/revert returns 401 when not signed in" do
    assert_api_response :put, 401, path_params: {id: @version.id}, body: {field: "cargo"}
  end

  test "PUT /versions/:id/revert returns 403 for an admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, path_params: {id: @version.id}, body: {field: "cargo"}
  end
end
