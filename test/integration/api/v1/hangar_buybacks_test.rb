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

  api_path "/hangar/sync-rsi-buyback-details" do
    put("Sync RSI Buy-back Pledge Details") do
      operationId "syncRsiBuybackDetails"
      tags "Hangar"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::SyncRsiBuybackDetailsInput

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Hangar::BuybackDetailsSyncResult
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

  test "GET /hangar/buybacks sorts by price, upgrades priced from their ships and unknown prices last" do
    user = create(:user)
    create(:model, rsi_id: 308, pledge_price: 150)
    create(:model, rsi_id: 322, pledge_price: 175)
    upgrade = buyback(user, kind: "upgrade", name: "Upgrade - Clipper to S-65 Stingray Standard Edition",
      upgrade_from_ship_id: 308, upgrade_to_ship_id: 322, upgrade_to_sku_id: 19461)
    expensive = buyback(user, name: "Standalone Ship - Hammerhead", price: 725)
    unpriced = buyback(user, name: "Standalone Ship - Aurora MR")
    sign_in user

    assert_api_response :get, 200, params: {q: {"s" => "price asc"}} do
      assert_equal [upgrade.id, expensive.id, unpriced.id], parsed_body["items"].pluck("id")
    end

    assert_api_response :get, 200, params: {q: {"s" => "price desc"}} do
      assert_equal [expensive.id, upgrade.id, unpriced.id], parsed_body["items"].pluck("id")
    end
  end

  test "GET /hangar/buybacks sorts by name, then by reclaim date for the same name" do
    user = create(:user)
    cutlass_older = buyback(user, reclaimed_on: Date.new(2023, 11, 26))
    cutlass_newer = buyback(user, reclaimed_on: Date.new(2026, 9, 21))
    aurora = buyback(user, name: "Standalone Ship - Aurora MR", reclaimed_on: Date.new(2024, 1, 1))
    sign_in user

    assert_api_response :get, 200, params: {q: {"sorts" => ["name desc", "reclaimedOn asc"]}} do
      assert_equal [cutlass_older.id, cutlass_newer.id, aurora.id], parsed_body["items"].pluck("id")
    end
  end

  test "GET /hangar/buybacks breaks a name or price tie by the latest reclaim, undated last" do
    user = create(:user)
    undated = buyback(user, price: 90)
    older = buyback(user, price: 90, reclaimed_on: Date.new(2023, 11, 26))
    newer = buyback(user, price: 90, reclaimed_on: Date.new(2026, 9, 21))
    sign_in user

    ["name asc", "price asc"].each do |sort|
      assert_api_response :get, 200, params: {q: {"s" => sort}} do
        assert_equal [newer.id, older.id, undated.id], parsed_body["items"].pluck("id")
      end
    end
  end

  test "GET /hangar/buybacks sorts by reclaim date, oldest first" do
    user = create(:user)
    newer = buyback(user, reclaimed_on: Date.new(2026, 9, 21))
    older = buyback(user, reclaimed_on: Date.new(2023, 11, 26))
    sign_in user

    assert_api_response :get, 200, params: {q: {"s" => "reclaimedOn asc"}} do
      assert_equal [older.id, newer.id], parsed_body["items"].pluck("id")
    end
  end

  test "GET /hangar/buybacks lists pledges without a reclaim date last" do
    user = create(:user)
    undated = buyback(user)
    dated = buyback(user, reclaimed_on: Date.new(2023, 11, 26))
    sign_in user

    assert_api_response :get, 200 do
      assert_equal [dated.id, undated.id], parsed_body["items"].pluck("id")
    end
  end

  test "GET /hangar/buybacks pages through identical pledges without repeating one" do
    user = create(:user)
    pledges = Array.new(3) { buyback(user, reclaimed_on: Date.new(2023, 11, 26)) }
    sign_in user

    ids = (1..3).flat_map do |page|
      get "/api/v1/hangar/buybacks", params: {page:, perPage: 1}

      parsed_body["items"].pluck("id")
    end

    assert_equal pledges.map(&:id).sort, ids
  end

  test "GET /hangar/buybacks refuses a sort it does not offer" do
    sign_in create(:user)

    get "/api/v1/hangar/buybacks", params: {q: {"s" => "rsiPledgeId asc"}}

    assert_response :bad_request
  end

  test "GET /hangar/buybacks prices an upgrade from both ships' store prices" do
    user = create(:user)
    create(:model, rsi_id: 308, pledge_price: 150)
    create(:model, rsi_id: 322, pledge_price: 175)
    buyback(user, kind: "upgrade", name: "Upgrade - Clipper to S-65 Stingray Standard Edition",
      upgrade_from_ship_id: 308, upgrade_to_ship_id: 322, upgrade_to_sku_id: 19461)
    buyback(user, kind: "upgrade", name: "Upgrade - Unknown", upgrade_from_ship_id: 308, upgrade_to_ship_id: 99999)
    sign_in user

    assert_api_response :get, 200 do
      priced, unknown = parsed_body["items"].sort_by { |item| item["name"] }

      assert_in_delta 25.0, priced["price"]
      assert_nil unknown["price"]
    end
  end

  test "GET /hangar/buybacks includes price, insurance and availability" do
    user = create(:user)
    buyback(user, available: false, price: 157.08, insurance_months: 120)
    sign_in user

    assert_api_response :get, 200 do
      item = parsed_body["items"].first

      assert_equal false, item["available"]
      assert_in_delta 157.08, item["price"]
      assert_equal 120, item["insuranceMonths"]
      assert_equal false, item["lifetimeInsurance"]
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

  test "GET /hangar/buybacks filters by a price range, upgrades priced from their ships" do
    user = create(:user)
    create(:model, rsi_id: 308, pledge_price: 150)
    create(:model, rsi_id: 322, pledge_price: 175)
    buyback(user, price: 10)
    mid = buyback(user, price: 60)
    upgrade = buyback(user, kind: "upgrade", name: "Upgrade - Clipper to S-65 Stingray Standard Edition",
      upgrade_from_ship_id: 308, upgrade_to_ship_id: 322)
    buyback(user, price: 500)
    sign_in user

    assert_api_response :get, 200, params: {q: {"priceGteq" => 20, "priceLteq" => 100}} do
      assert_equal [mid.id, upgrade.id].sort, parsed_body["items"].pluck("id").sort
    end
  end

  test "GET /hangar/buybacks filters by preset price ranges" do
    user = create(:user)
    cheap = buyback(user, price: 10)
    buyback(user, price: 60)
    expensive = buyback(user, price: 1500)
    buyback(user, price: nil)
    sign_in user

    assert_api_response :get, 200, params: {q: {"priceIn" => ["-25", "1000-"]}} do
      assert_equal [cheap.id, expensive.id].sort, parsed_body["items"].pluck("id").sort
    end
  end

  test "GET /hangar/buybacks filters by insurance" do
    user = create(:user)
    lifetime = buyback(user, lifetime_insurance: true, insurance_months: 120)
    ten_years = buyback(user, insurance_months: 120)
    one_month = buyback(user, insurance_months: 1)
    buyback(user, insurance_months: 6)
    uninsured = buyback(user, details_synced_at: Time.current)
    zero_months = buyback(user, insurance_months: 0, details_synced_at: Time.current)
    upgrade = buyback(user, kind: "upgrade", name: "Upgrade - Clipper to S-65 Stingray")
    buyback(user)
    sign_in user

    assert_api_response :get, 200, params: {q: {"insuranceIn" => ["lifetime", "120"]}} do
      assert_equal [lifetime.id, ten_years.id].sort, parsed_body["items"].pluck("id").sort
    end

    assert_api_response :get, 200, params: {q: {"insuranceIn" => ["120"]}} do
      assert_equal [ten_years.id], parsed_body["items"].pluck("id")
    end

    assert_api_response :get, 200, params: {q: {"insuranceIn" => ["1"]}} do
      assert_equal [one_month.id], parsed_body["items"].pluck("id")
    end

    assert_api_response :get, 200, params: {q: {"insuranceIn" => ["none"]}} do
      assert_equal [uninsured.id, zero_months.id, upgrade.id].sort, parsed_body["items"].pluck("id").sort
    end
  end

  test "GET /hangar/buybacks matches nothing for an insurance value it cannot read" do
    user = create(:user)
    buyback(user, insurance_months: 8)
    buyback(user, insurance_months: 120)
    sign_in user

    ["lti", "0", "010x", "0x10", "99999999999999999999"].each do |value|
      assert_api_response :get, 200, params: {q: {"insuranceIn" => [value]}} do
        assert_empty parsed_body["items"], value
      end
    end
  end

  test "GET /hangar/buybacks filters upgrades by the ship they start from and lead to" do
    user = create(:user)
    clipper = create(:model, rsi_id: 308)
    stingray = create(:model, rsi_id: 322)
    cutlass = create(:model, rsi_id: 100)
    to_stingray = buyback(user, kind: "upgrade", name: "Upgrade - Clipper to S-65 Stingray",
      upgrade_from_ship_id: 308, upgrade_to_ship_id: 322)
    to_cutlass = buyback(user, kind: "upgrade", name: "Upgrade - Clipper to Cutlass Black",
      upgrade_from_ship_id: 308, upgrade_to_ship_id: 100)
    buyback(user)
    sign_in user

    assert_api_response :get, 200, params: {q: {"upgradeFromModelSlugEq" => clipper.slug}} do
      assert_equal [to_stingray.id, to_cutlass.id].sort, parsed_body["items"].pluck("id").sort
    end

    assert_api_response :get, 200, params: {q: {"upgradeToModelSlugEq" => stingray.slug}} do
      assert_equal [to_stingray.id], parsed_body["items"].pluck("id")
    end

    assert_api_response :get, 200, params: {q: {"upgradeFromModelSlugEq" => cutlass.slug}} do
      assert_empty parsed_body["items"]
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
       available: false, upgradeFromShipId: 308, upgradeToShipId: 322, upgradeToSkuId: 19461}
    ]}

    assert_api_response :put, 200, api_path: "/hangar/sync-rsi-buybacks", body: body do
      assert_equal({"total" => 2, "added" => 2, "removed" => 0}, parsed_body.except("detailsPending"))
      assert_equal %w[44725819], parsed_body["detailsPending"]
    end

    cutter = user.buyback_pledges.find_by!(rsi_pledge_id: "44725819")

    assert_predicate cutter, :upgraded?
    assert_equal Date.new(2023, 11, 26), cutter.reclaimed_on
    assert_equal "Cutter Scout and 3 items", cutter.contained
    assert_predicate cutter, :available?
    assert_equal 19461, user.buyback_pledges.find_by!(rsi_pledge_id: "111313560").upgrade_to_sku_id
    assert_not user.buyback_pledges.find_by!(rsi_pledge_id: "111313560").available?
  end

  test "PUT /hangar/sync-rsi-buybacks keeps stored details and only lists pledges without them" do
    user = create(:user)
    priced = buyback(user, rsi_pledge_id: "1", price: 94.25, insurance_months: 6,
      details_synced_at: 1.day.ago)
    sign_in user

    body = {items: [
      {id: "1", kind: "ship", name: "Standalone Ship - Aegis Gladius", available: false},
      {id: "2", kind: "paint", name: "Paints - Sabre - Tribunal Paint"}
    ]}

    assert_api_response :put, 200, api_path: "/hangar/sync-rsi-buybacks", body: body do
      assert_equal %w[2], parsed_body["detailsPending"]
    end

    priced.reload

    assert_in_delta 94.25, priced.price
    assert_equal 6, priced.insurance_months
    assert_not priced.available?
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

    assert_api_response :put, 200, api_path: "/hangar/sync-rsi-buybacks", body: body do
      assert_equal({"total" => 2, "added" => 1, "removed" => 1}, parsed_body.except("detailsPending"))
    end

    assert_equal %w[1 3], user.buyback_pledges.order(:rsi_pledge_id).pluck(:rsi_pledge_id)
    assert_equal "Standalone Ship - Cutlass Black", kept.reload.name
  end

  test "PUT /hangar/sync-rsi-buybacks with an empty list clears it" do
    user = create(:user)
    buyback(user)
    sign_in user

    assert_api_response :put, 200, api_path: "/hangar/sync-rsi-buybacks", body: {items: []} do
      assert_equal 1, parsed_body["removed"]
    end

    assert_empty user.buyback_pledges
  end

  test "PUT /hangar/sync-rsi-buybacks keeps one row for a pledge listed twice" do
    user = create(:user)
    sign_in user

    item = {id: "1", kind: "ship", name: "Standalone Ship - Cutlass Black"}

    assert_api_response :put, 200, api_path: "/hangar/sync-rsi-buybacks", body: {items: [item, item]} do
      assert_equal 1, parsed_body["total"]
    end
  end

  test "PUT /hangar/sync-rsi-buybacks leaves somebody else's list alone" do
    user = create(:user)
    other = buyback(create(:user))
    sign_in user

    assert_api_response :put, 200, api_path: "/hangar/sync-rsi-buybacks", body: {items: []}

    assert BuybackPledge.exists?(other.id)
  end

  test "PUT /hangar/sync-rsi-buybacks without a list is refused" do
    user = create(:user)
    buyback(user)
    sign_in user

    assert_api_response :put, 400, api_path: "/hangar/sync-rsi-buybacks", body: {}

    assert_equal 1, user.buyback_pledges.count
  end

  test "PUT /hangar/sync-rsi-buybacks does not read a null list as an empty one" do
    user = create(:user)
    buyback(user)
    sign_in user

    assert_api_response :put, 400, api_path: "/hangar/sync-rsi-buybacks", body: {items: nil}

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

    assert_api_response :put, 400, api_path: "/hangar/sync-rsi-buybacks", body: body

    assert_equal %w[1 2], user.buyback_pledges.order(:rsi_pledge_id).pluck(:rsi_pledge_id)
  end

  test "PUT /hangar/sync-rsi-buybacks requires a session or token" do
    assert_api_response :put, 401, api_path: "/hangar/sync-rsi-buybacks", body: {items: []}
  end

  test "PUT /hangar/sync-rsi-buyback-details stores price and insurance" do
    user = create(:user)
    gladius = buyback(user, rsi_pledge_id: "1")
    cutter = buyback(user, rsi_pledge_id: "2")
    upgrade = buyback(user, rsi_pledge_id: "3", kind: "upgrade")
    sign_in user

    body = {items: [
      {id: "1", price: 94.25, insuranceMonths: 6},
      {id: "2", price: 41.89, lifetimeInsurance: true},
      {id: "3"}
    ]}

    assert_api_response :put, 200, api_path: "/hangar/sync-rsi-buyback-details", body: body do
      assert_equal({"updated" => 3}, parsed_body)
    end

    gladius.reload

    assert_in_delta 94.25, gladius.price
    assert_equal 6, gladius.insurance_months
    assert_not gladius.lifetime_insurance?
    assert_predicate gladius.details_synced_at, :present?
    assert_predicate cutter.reload, :lifetime_insurance?

    upgrade.reload

    assert_nil upgrade.price
    assert_predicate upgrade.details_synced_at, :present?
  end

  # An extension from before availability sends none; that is no evidence the
  # pledge became available again.
  test "PUT /hangar/sync-rsi-buybacks keeps the stored availability of an entry without one" do
    user = create(:user)
    stored = buyback(user, rsi_pledge_id: "1", available: false)
    sign_in user

    body = {items: [
      {id: "1", kind: "ship", name: "Standalone Ship - Aegis Gladius"},
      {id: "2", kind: "ship", name: "Standalone Ship - Cutlass Black"},
      {id: "3", kind: "ship", name: "Standalone Ship - Cutter", available: false}
    ]}

    assert_api_response :put, 200, api_path: "/hangar/sync-rsi-buybacks", body: body

    assert_not stored.reload.available?
    assert_predicate user.buyback_pledges.find_by!(rsi_pledge_id: "2"), :available?
    assert_not user.buyback_pledges.find_by!(rsi_pledge_id: "3").available?
  end

  test "PUT /hangar/sync-rsi-buybacks reads stored details only once" do
    user = create(:user)
    buyback(user, rsi_pledge_id: "1", price: 10, details_synced_at: 1.year.ago)
    sign_in user

    body = {items: [{id: "1", kind: "ship", name: "Standalone Ship - Aegis Gladius"}]}

    assert_api_response :put, 200, api_path: "/hangar/sync-rsi-buybacks", body: body do
      assert_empty parsed_body["detailsPending"]
    end
  end

  test "PUT /hangar/sync-rsi-buyback-details leaves somebody else's pledge alone" do
    user = create(:user)
    other = buyback(create(:user), rsi_pledge_id: "1")
    sign_in user

    assert_api_response :put, 200, api_path: "/hangar/sync-rsi-buyback-details", body: {items: [{id: "1", price: 10}]} do
      assert_equal 0, parsed_body["updated"]
    end

    assert_nil other.reload.price
  end

  test "PUT /hangar/sync-rsi-buyback-details without a list is refused" do
    sign_in create(:user)

    assert_api_response :put, 400, api_path: "/hangar/sync-rsi-buyback-details", body: {}
  end

  test "PUT /hangar/sync-rsi-buyback-details requires a session or token" do
    assert_api_response :put, 401, api_path: "/hangar/sync-rsi-buyback-details", body: {items: []}
  end
end
