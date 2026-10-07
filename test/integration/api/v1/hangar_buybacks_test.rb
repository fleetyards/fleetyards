# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarBuybacksTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/hangar/buybacks" do
    get("Hangar Buy-back Pledges") do
      operationId "hangarBuybacks"
      tags "Hangar"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:read"]},
        {OpenId: ["hangar", "hangar:read"]}
      ]

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {
        type: :string, default: BuybackPledge.default_per_page
      }, required: false
      parameter name: "q", in: :query,
        schema: ::V1::Schemas::Queries::BuybackPledgeQuery,
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema ::V1::Schemas::Hangar::BuybackPledges
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/hangar/sync-rsi-buybacks" do
    put("Sync RSI Buy-back Pledges") do
      operationId "syncRsiBuybacks"
      tags "Hangar"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::SyncRsiBuybacksInput

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Hangar::BuybackSyncResult
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  def buyback(user, **attributes)
    BuybackPledge.create!(
      user:, rsi_pledge_id: SecureRandom.random_number(10**8).to_s, kind: "ship", name: "Standalone Ship - Cutlass Black",
      **attributes
    )
  end

  test "GET /hangar/buybacks lists the caller's buy-back pledges, latest reclaim first" do
    user = create(:user)
    older = buyback(user, reclaimed_on: Date.new(2023, 11, 26))
    newer = buyback(user, kind: "upgrade", name: "Upgrade - Clipper to S-65 Stingray Standard Edition",
      reclaimed_on: Date.new(2026, 9, 21), upgrade_from_ship_id: 308, upgrade_to_ship_id: 322, upgrade_to_sku_id: 19461)
    sign_in user

    assert_api_response :get, 200 do
      assert_equal [newer.id, older.id], parsed_body["items"].pluck("id")
      assert_equal "2026-09-21", parsed_body["items"].first["reclaimedOn"]
      assert_equal 322, parsed_body["items"].first["upgradeToShipId"]
    end
  end

  test "GET /hangar/buybacks does not list somebody else's" do
    user = create(:user)
    buyback(create(:user))
    sign_in user

    assert_api_response :get, 200 do
      assert_empty parsed_body["items"]
    end
  end

  test "GET /hangar/buybacks filters by kind" do
    user = create(:user)
    buyback(user)
    paint = buyback(user, kind: "paint", name: "Paints - Sabre - Beyond Paint")
    sign_in user

    assert_api_response :get, 200, params: {q: {"kindEq" => "paint"}} do
      assert_equal [paint.id], parsed_body["items"].pluck("id")
    end
  end

  test "GET /hangar/buybacks requires a session or token" do
    assert_api_response :get, 401
  end

  test "PUT /hangar/sync-rsi-buybacks stores the list" do
    user = create(:user)
    sign_in user

    body = {items: [
      {id: "44725819", kind: "ship", name: "Standalone Ship - Cutter plus Groundswell Paint", upgraded: true,
       reclaimedOn: "2023-11-26", contained: "Cutter Scout and 3 items",
       image: "https://robertsspaceindustries.com/media/s1pzv94jrc3jhr/heap_infobox/cutter.jpg"},
      {id: "111313560", kind: "upgrade", name: "Upgrade - Clipper to S-65 Stingray Standard Edition",
       upgradeFromShipId: 308, upgradeToShipId: 322, upgradeToSkuId: 19461}
    ]}

    assert_api_response :put, 200, body: body do
      assert_equal({"total" => 2, "added" => 2, "removed" => 0}, parsed_body)
    end

    cutter = user.buyback_pledges.find_by!(rsi_pledge_id: "44725819")

    assert_predicate cutter, :upgraded?
    assert_equal Date.new(2023, 11, 26), cutter.reclaimed_on
    assert_equal "Cutter Scout and 3 items", cutter.contained
    assert_equal 19461, user.buyback_pledges.find_by!(rsi_pledge_id: "111313560").upgrade_to_sku_id
  end

  test "PUT /hangar/sync-rsi-buybacks replaces the previous list" do
    user = create(:user)
    kept = buyback(user, rsi_pledge_id: "1", name: "Old name")
    buyback(user, rsi_pledge_id: "2")
    sign_in user

    body = {items: [
      {id: "1", kind: "ship", name: "Standalone Ship - Cutlass Black"},
      {id: "3", kind: "paint", name: "Paints - Sabre - Tribunal Paint"}
    ]}

    assert_api_response :put, 200, body: body do
      assert_equal({"total" => 2, "added" => 1, "removed" => 1}, parsed_body)
    end

    assert_equal %w[1 3], user.buyback_pledges.order(:rsi_pledge_id).pluck(:rsi_pledge_id)
    assert_equal "Standalone Ship - Cutlass Black", kept.reload.name
  end

  test "PUT /hangar/sync-rsi-buybacks with an empty list clears it" do
    user = create(:user)
    buyback(user)
    sign_in user

    assert_api_response :put, 200, body: {items: []} do
      assert_equal 1, parsed_body["removed"]
    end

    assert_empty user.buyback_pledges
  end

  test "PUT /hangar/sync-rsi-buybacks keeps one row for a pledge listed twice" do
    user = create(:user)
    sign_in user

    item = {id: "1", kind: "ship", name: "Standalone Ship - Cutlass Black"}

    assert_api_response :put, 200, body: {items: [item, item]} do
      assert_equal 1, parsed_body["total"]
    end
  end

  test "PUT /hangar/sync-rsi-buybacks leaves somebody else's list alone" do
    user = create(:user)
    other = buyback(create(:user))
    sign_in user

    assert_api_response :put, 200, body: {items: []}

    assert BuybackPledge.exists?(other.id)
  end

  test "PUT /hangar/sync-rsi-buybacks without a list is refused" do
    user = create(:user)
    buyback(user)
    sign_in user

    assert_api_response :put, 400, body: {}

    assert_equal 1, user.buyback_pledges.count
  end

  test "PUT /hangar/sync-rsi-buybacks does not read a null list as an empty one" do
    user = create(:user)
    buyback(user)
    sign_in user

    assert_api_response :put, 400, body: {items: nil}

    assert_equal 1, user.buyback_pledges.count
  end

  # Dropping the entry instead would delete its stored row while the sync
  # reported success.
  test "PUT /hangar/sync-rsi-buybacks refuses the whole list when one entry has no name" do
    user = create(:user)
    buyback(user, rsi_pledge_id: "1")
    buyback(user, rsi_pledge_id: "2")
    sign_in user

    body = {items: [
      {id: "1", kind: "ship", name: "Standalone Ship - Cutlass Black"},
      {id: "2", kind: "ship", name: ""}
    ]}

    assert_api_response :put, 400, body: body

    assert_equal %w[1 2], user.buyback_pledges.order(:rsi_pledge_id).pluck(:rsi_pledge_id)
  end

  test "PUT /hangar/sync-rsi-buybacks requires a session or token" do
    assert_api_response :put, 401, body: {items: []}
  end
end
