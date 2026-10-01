# frozen_string_literal: true

require "openapi_helper"

class Api::V1::CatalogueLookupTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/catalogue/lookup" do
    get("Resolve the catalogue items a text names inline") do
      operationId "catalogueLookup"
      tags "Catalogue"
      produces "application/json"

      parameter name: :names, in: :query, schema: {type: :array, items: {type: :string}, maxItems: 100}, style: :form, explode: true, required: true,
        description: "Token texts: `Name` or `type:Name`. A contract, an event or a user (`contract:FID/Title`, `event:FID/Title`, `user:handle`) resolves only for a reader allowed to see it"

      response(200, "the names that resolve to exactly one listed item") do
        schema ::V1::Schemas::CatalogueTokenMatches
      end
    end
  end

  test "GET /catalogue/lookup resolves a name to its one item" do
    commodity = create(:commodity, name: "Quantainium")

    assert_api_response :get, 200, params: {names: ["Quantainium", "Nothing By This Name"]} do
      assert_equal [{"token" => "Quantainium", "name" => "Quantainium", "type" => "Commodity", "slug" => commodity.slug}], parsed_body["items"]
    end
  end

  test "GET /catalogue/lookup resolves a contract only for a reader who may see it" do
    Flipper.enable("fleet_contracts")
    member = create(:user)
    fleet = create(:fleet, fid: "MARU", members: [member])
    contract = create(:fleet_contract, :published, fleet:, title: "Salvage Run")
    params = {names: ["contract:MARU/Salvage Run"]}

    assert_api_response :get, 200, params: do
      assert_empty parsed_body["items"]
    end

    sign_in member

    assert_api_response :get, 200, params: do
      assert_equal [{"token" => "contract:MARU/Salvage Run", "name" => "Salvage Run", "type" => "FleetContract",
                     "slug" => contract.slug, "fleetSlug" => fleet.slug}], parsed_body["items"]
    end
  end

  test "GET /catalogue/lookup resolves no contract for an OAuth token that may not read fleets" do
    Flipper.enable("fleet_contracts")
    member = create(:user)
    fleet = create(:fleet, fid: "MARU", members: [member])
    create(:fleet_contract, :published, fleet:, title: "Salvage Run")
    params = {names: ["contract:MARU/Salvage Run"]}

    narrow = create(:oauth_access_token, resource_owner_id: member.id, scopes: ["public"])

    assert_api_response :get, 200, params:, headers: {"Authorization" => "Bearer #{narrow.token}"} do
      assert_empty parsed_body["items"]
    end

    wide = create(:oauth_access_token, resource_owner_id: member.id, scopes: ["fleet:read"])

    assert_api_response :get, 200, params:, headers: {"Authorization" => "Bearer #{wide.token}"} do
      assert_equal ["contract:MARU/Salvage Run"], parsed_body["items"].map { |item| item["token"] }
    end
  end

  test "GET /catalogue/lookup resolves nothing for an expired or revoked OAuth token" do
    Flipper.enable("fleet_contracts")
    member = create(:user)
    fleet = create(:fleet, fid: "MARU", members: [member])
    create(:fleet_contract, :published, fleet:, title: "Salvage Run")
    friend = create(:user, username: "FriendsOnly", public_hangar: false, friends_hangar: true)
    create(:friendship, :accepted, requester: member, addressee: friend)
    params = {names: ["contract:MARU/Salvage Run", "user:FriendsOnly"]}

    revoked = create(:oauth_access_token, resource_owner_id: member.id, scopes: ["fleet:read"], revoked_at: 1.minute.ago)
    expired = create(:oauth_access_token, resource_owner_id: member.id, scopes: ["fleet:read"], expires_in: 60, created_at: 1.hour.ago)

    [revoked, expired].each do |token|
      assert_api_response :get, 200, params:, headers: {"Authorization" => "Bearer #{token.token}"} do
        assert_empty parsed_body["items"]
      end
    end
  end
end
