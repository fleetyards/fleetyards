# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetchartLayoutsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  READ_SECURITY = [
    {SessionCookie: []},
    {Oauth2: ["hangar", "hangar:read"]},
    {OpenId: ["hangar", "hangar:read"]}
  ].freeze

  WRITE_SECURITY = [
    {SessionCookie: []},
    {Oauth2: ["hangar", "hangar:write"]},
    {OpenId: ["hangar", "hangar:write"]}
  ].freeze

  api_path "/hangar/fleetchart-layouts" do
    get("Fleetchart Layouts") do
      operationId "fleetchartLayouts"
      tags "FleetchartLayouts"
      produces "application/json"
      security READ_SECURITY

      response(200, "successful") { schema ::V1::Schemas::Hangar::FleetchartLayouts::FleetchartLayoutsList }
      response(401, "unauthorized") { schema ::Shared::V1::Schemas::StandardError }
      response(403, "feature disabled") { schema ::Shared::V1::Schemas::StandardError }
    end

    post("Create Fleetchart Layout") do
      operationId "createFleetchartLayout"
      tags "FleetchartLayouts"
      consumes "application/json"
      produces "application/json"
      security WRITE_SECURITY

      request_body required: true, schema: ::V1::Schemas::Inputs::FleetchartLayoutInput

      response(201, "successful") { schema ::V1::Schemas::Hangar::FleetchartLayouts::FleetchartLayout }
      response(400, "validation error") { schema ::Shared::V1::Schemas::ValidationError }
      response(401, "unauthorized") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  api_path "/hangar/fleetchart-layouts/{id}" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, required: true

    get("Fleetchart Layout") do
      operationId "fleetchartLayout"
      tags "FleetchartLayouts"
      produces "application/json"
      security READ_SECURITY

      response(200, "successful") { schema ::V1::Schemas::Hangar::FleetchartLayouts::FleetchartLayout }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end

    put("Update Fleetchart Layout") do
      operationId "updateFleetchartLayout"
      tags "FleetchartLayouts"
      consumes "application/json"
      produces "application/json"
      security WRITE_SECURITY

      request_body required: true, schema: ::V1::Schemas::Inputs::FleetchartLayoutInput

      response(200, "successful") { schema ::V1::Schemas::Hangar::FleetchartLayouts::FleetchartLayout }
      response(400, "validation error") { schema ::Shared::V1::Schemas::ValidationError }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end

    delete("Delete Fleetchart Layout") do
      operationId "destroyFleetchartLayout"
      tags "FleetchartLayouts"
      produces "application/json"
      security WRITE_SECURITY

      response(200, "successful") { schema ::V1::Schemas::SuccessResponse }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  api_path "/hangar/fleetchart-layouts/{id}/share" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, required: true

    put("Share Fleetchart Layout") do
      operationId "shareFleetchartLayout"
      tags "FleetchartLayouts"
      produces "application/json"
      security WRITE_SECURITY

      response(200, "successful") { schema ::V1::Schemas::Hangar::FleetchartLayouts::FleetchartLayout }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end

    delete("Unshare Fleetchart Layout") do
      operationId "unshareFleetchartLayout"
      tags "FleetchartLayouts"
      produces "application/json"
      security WRITE_SECURITY

      response(200, "successful") { schema ::V1::Schemas::Hangar::FleetchartLayouts::FleetchartLayout }
    end
  end

  api_path "/public/fleetchart-layouts/{token}" do
    parameter name: "token", in: :path, schema: {type: :string}, required: true

    get("Shared Fleetchart Layout") do
      operationId "publicFleetchartLayout"
      tags "FleetchartLayoutsPublic"
      produces "application/json"

      response(200, "successful") { schema ::V1::Schemas::Hangar::FleetchartLayouts::SharedFleetchartLayout }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  setup do
    Flipper.enable(:fleetchart_layouts)
    @user = create(:user)
    @vehicle = create(:vehicle, user: @user, public: true)
  end

  def placement_for(vehicle, **attributes)
    {vehicleId: vehicle.id, x: 12.5, y: -4, facing: "top", viewpoint: "rear", state: "landed", order: 2, groupId: "g1", heading: "Anvil"}
      .merge(attributes)
  end

  test "POST saves a layout, every field of a placement included" do
    sign_in @user

    post "/api/v1/hangar/fleetchart-layouts",
      params: {name: "Parade", colored: false, placements: [placement_for(@vehicle)]},
      as: :json

    assert_response :created
    body = response.parsed_body

    assert_equal "Parade", body["name"]
    assert_equal false, body["colored"]
    assert_equal(
      {"vehicleId" => @vehicle.id, "x" => 12.5, "y" => -4, "facing" => "top", "viewpoint" => "rear",
       "state" => "landed", "order" => 2, "groupId" => "g1", "heading" => "Anvil"},
      body["placements"].first
    )
  end

  test "POST rejects a duplicate name" do
    sign_in @user
    create(:fleetchart_layout, user: @user, name: "Parade")

    post "/api/v1/hangar/fleetchart-layouts", params: {name: "Parade"}, as: :json

    assert_response :bad_request
  end

  test "POST rejects a placement without coordinates or with an unknown view" do
    sign_in @user

    post "/api/v1/hangar/fleetchart-layouts",
      params: {name: "Broken", placements: [placement_for(@vehicle, viewpoint: "nope")]},
      as: :json

    assert_response :bad_request
  end

  test "saving drops ships that are not the user's" do
    sign_in @user
    foreign = create(:vehicle)

    post "/api/v1/hangar/fleetchart-layouts",
      params: {name: "Parade", placements: [placement_for(@vehicle), placement_for(foreign)]},
      as: :json

    assert_response :created
    assert_equal [@vehicle.id], response.parsed_body["placements"].map { |placement| placement["vehicleId"] }
  end

  test "a user only reaches their own layouts" do
    other = create(:fleetchart_layout)
    mine = create(:fleetchart_layout, user: @user)
    sign_in @user

    get "/api/v1/hangar/fleetchart-layouts"
    assert_equal [mine.id], response.parsed_body.map { |layout| layout["id"] }

    put "/api/v1/hangar/fleetchart-layouts/#{other.id}", params: {name: "Mine now"}, as: :json
    assert_response :not_found
    assert_not_equal "Mine now", other.reload.name
  end

  test "the feature flag closes the API" do
    Flipper.disable(:fleetchart_layouts)
    sign_in @user

    get "/api/v1/hangar/fleetchart-layouts"

    assert_response :forbidden
  end

  test "signed out gets a 401" do
    get "/api/v1/hangar/fleetchart-layouts"

    assert_response :unauthorized
  end

  test "a shared layout shows every ship placed in it, whatever the hangar's settings" do
    private_ship = create(:vehicle, user: @user, public: false)
    unplaced = create(:vehicle, user: @user, public: true)
    @user.update!(public_hangar: false)
    layout = create(:fleetchart_layout, user: @user, placements: [
      {"vehicle_id" => @vehicle.id, "x" => 1, "y" => 1},
      {"vehicle_id" => private_ship.id, "x" => 2, "y" => 2}
    ])
    layout.share!

    get "/api/v1/public/fleetchart-layouts/#{layout.share_token}"

    assert_response :success
    body = response.parsed_body

    assert_equal [@vehicle.id, private_ship.id].sort, body["placements"].map { |placement| placement["vehicleId"] }.sort
    assert_equal [@vehicle.id, private_ship.id].sort, body["vehicles"].map { |vehicle| vehicle["id"] }.sort
    assert_not_includes response.body, unplaced.id
    assert_nil body["id"]
    assert_nil body["shareToken"]
  end

  test "a shared layout names its owner, unless they hide their name" do
    layout = create(:fleetchart_layout, user: @user)
    layout.share!

    get "/api/v1/public/fleetchart-layouts/#{layout.share_token}"

    assert_equal @user.username, response.parsed_body["username"]
    assert_equal true, response.parsed_body["publicHangar"]

    @user.update!(hide_owner: true)

    get "/api/v1/public/fleetchart-layouts/#{layout.share_token}"

    assert_nil response.parsed_body["username"]
    assert_equal false, response.parsed_body["publicHangar"]
    assert_not_includes response.body, @user.username
  end

  test "a ship sold since the layout was saved drops out of the shared layout" do
    sold = create(:vehicle, user: @user, public: true)
    layout = create(:fleetchart_layout, user: @user, placements: [
      {"vehicle_id" => @vehicle.id, "x" => 1, "y" => 1},
      {"vehicle_id" => sold.id, "x" => 2, "y" => 2}
    ])
    layout.share!
    sold.destroy!

    get "/api/v1/public/fleetchart-layouts/#{layout.share_token}"

    assert_equal [@vehicle.id], response.parsed_body["placements"].map { |placement| placement["vehicleId"] }
  end

  test "sharing again keeps the link, and unsharing closes it" do
    layout = create(:fleetchart_layout, user: @user)
    sign_in @user

    put "/api/v1/hangar/fleetchart-layouts/#{layout.id}/share"
    token = response.parsed_body["shareToken"]
    assert token.present?

    put "/api/v1/hangar/fleetchart-layouts/#{layout.id}/share"
    assert_equal token, response.parsed_body["shareToken"]

    delete "/api/v1/hangar/fleetchart-layouts/#{layout.id}/share"
    assert_nil response.parsed_body["shareToken"]

    get "/api/v1/public/fleetchart-layouts/#{token}"
    assert_response :not_found
  end

  test "an unknown token is not found, and so is one whose owner lost the feature" do
    get "/api/v1/public/fleetchart-layouts/nope"
    assert_response :not_found

    layout = create(:fleetchart_layout, user: @user)
    layout.share!
    Flipper.disable(:fleetchart_layouts)

    get "/api/v1/public/fleetchart-layouts/#{layout.share_token}"
    assert_response :not_found
  end
end
