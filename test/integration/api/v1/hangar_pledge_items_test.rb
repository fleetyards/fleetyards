# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarPledgeItemsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  {
    "/hangar/paints" => ["Hangar Paints", "hangarPaints"],
    "/hangar/flair" => ["Hangar Flair", "hangarFlair"]
  }.each do |path, (summary, operation_id)|
    api_path path do
      get(summary) do
        operationId operation_id
        tags "Hangar"
        produces "application/json"

        security [
          {SessionCookie: []},
          {Oauth2: ["hangar", "hangar:read"]},
          {OpenId: ["hangar", "hangar:read"]}
        ]

        parameter "$ref": "#/components/parameters/PageParameter"
        parameter name: "perPage", in: :query, schema: {
          type: :string, default: HangarPledgeItem.default_per_page
        }, required: false
        parameter name: "q", in: :query,
          schema: ::V1::Schemas::Queries::HangarPledgeItemQuery,
          style: :deepObject,
          explode: true,
          required: false

        response(200, "successful") do
          schema ::V1::Schemas::Hangar::HangarPledgeItems
        end

        response(401, "unauthorized") do
          schema ::Shared::V1::Schemas::StandardError
        end
      end
    end
  end

  test "GET /hangar/paints lists the caller's paints newest pledge first, as RSI does" do
    user = create(:user)
    older = create(:hangar_pledge_item, user:, rsi_pledge_id: "9000001", pledge_created_on: Date.new(2024, 5, 1))
    newer = create(:hangar_pledge_item, user:, rsi_pledge_id: "112870675", name: "Stingray - Marina Paint", quantity: 2,
      pledge_created_on: Date.new(2026, 10, 8), image_url: "https://media.robertsspaceindustries.com/marina/source.jpg")
    same_day = create(:hangar_pledge_item, user:, rsi_pledge_id: "112870680", name: "Zeus - Solar Paint", pledge_created_on: Date.new(2026, 10, 8))
    undated = create(:hangar_pledge_item, user:, rsi_pledge_id: "99999999", name: "Aurora - Dark Green Paint")
    create(:hangar_pledge_item, user:, kind: "flair", name: "Takuetsu Cutlass Model")
    sign_in user

    assert_api_response :get, 200, api_path: "/hangar/paints" do
      assert_equal [same_day.id, newer.id, older.id, undated.id], parsed_body["items"].pluck("id")
      assert_equal 2, parsed_body["items"].second["quantity"]
      assert_equal "2026-10-08", parsed_body["items"].second["pledgeCreatedOn"]
      assert_equal "https://media.robertsspaceindustries.com/marina/source.jpg", parsed_body["items"].second["image"]
    end
  end

  test "GET /hangar/paints filters to what RSI offers to melt" do
    user = create(:user)
    meltable = create(:hangar_pledge_item, user:, meltable: true)
    create(:hangar_pledge_item, user:, name: "Constellation Mk IV - Disco Paint", meltable: false)
    sign_in user

    assert_api_response :get, 200, api_path: "/hangar/paints", params: {q: {"meltableEq" => true}} do
      assert_equal [meltable.id], parsed_body["items"].pluck("id")
      assert parsed_body["items"].first["meltable"]
    end
  end

  test "GET /hangar/flair filters to items whose pledge is worth something" do
    user = create(:user)
    valued = create(:hangar_pledge_item, user:, kind: "flair", name: "Space Globe - Terra", pledge_value: 5)
    create(:hangar_pledge_item, user:, kind: "flair", name: "200M Commemorative Coin", pledge_value: 0)
    create(:hangar_pledge_item, user:, kind: "flair", name: "Unpriced Trophy")
    sign_in user

    assert_api_response :get, 200, api_path: "/hangar/flair", params: {q: {"withValue" => true}} do
      assert_equal [valued.id], parsed_body["items"].pluck("id")
    end
  end

  test "GET /hangar/paints gives a melt value only to an item that is its whole pledge" do
    user = create(:user)
    create(:hangar_pledge_item, user:, name: "Cutlass - Akuma Paint", pledge_name: "Paints - Cutlass - Akuma Paint", pledge_value: 10, pledge_item_count: 1)
    create(:hangar_pledge_item, user:, name: "CSV - Granite Paint", pledge_name: "Standalone Ships - CSV-SM plus Granite Paint",
      pledge_value: 40, pledge_item_count: 3)
    create(:hangar_pledge_item, user:, kind: "flair", name: "Poster - Banu Merchantman", pledge_value: 6, pledge_item_count: 2, quantity: 2)
    sign_in user

    assert_api_response :get, 200, api_path: "/hangar/paints" do
      items = parsed_body["items"].index_by { |item| item["name"] }
      standalone = items.fetch("Cutlass - Akuma Paint")
      bundled = items.fetch("CSV - Granite Paint")

      assert standalone["standalone"]
      assert_in_delta 10.0, standalone["meltValue"]
      assert_not bundled["standalone"]
      assert_nil bundled["meltValue"]
      assert_in_delta 40.0, bundled["pledgeValue"]
      assert_equal "Standalone Ships - CSV-SM plus Granite Paint", bundled["pledgeName"]
    end

    assert_api_response :get, 200, api_path: "/hangar/flair" do
      poster = parsed_body["items"].sole

      assert poster["standalone"]
      assert_in_delta 6.0, poster["meltValue"]
    end
  end

  test "GET /hangar/flair lists only the caller's flair" do
    user = create(:user)
    create(:hangar_pledge_item, user:)
    poster = create(:hangar_pledge_item, user:, kind: "flair", name: "Poster - Banu Merchantman")
    create(:hangar_pledge_item, kind: "flair", name: "Space Globe - Terra")
    sign_in user

    assert_api_response :get, 200, api_path: "/hangar/flair" do
      assert_equal [poster.id], parsed_body["items"].pluck("id")
      assert_equal "flair", parsed_body["items"].first["kind"]
    end
  end

  test "GET /hangar/paints filters by name" do
    user = create(:user)
    create(:hangar_pledge_item, user:)
    marina = create(:hangar_pledge_item, user:, name: "Stingray - Marina Paint")
    sign_in user

    assert_api_response :get, 200, api_path: "/hangar/paints", params: {q: {"nameCont" => "marina"}} do
      assert_equal [marina.id], parsed_body["items"].pluck("id")
    end
  end

  test "GET /hangar/paints requires a session or token" do
    assert_api_response :get, 401, api_path: "/hangar/paints"
  end

  test "GET /hangar/flair requires a session or token" do
    assert_api_response :get, 401, api_path: "/hangar/flair"
  end
end
