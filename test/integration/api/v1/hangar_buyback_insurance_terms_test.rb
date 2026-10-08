# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarBuybackInsuranceTermsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/hangar/buybacks/insurance-terms" do
    get("Hangar Buy-back Insurance Terms") do
      operationId "hangarBuybackInsuranceTerms"
      tags "Hangar"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:read"]},
        {OpenId: ["hangar", "hangar:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Hangar::BuybackInsuranceTerms
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

  test "GET /hangar/buybacks/insurance-terms lists the caller's own terms" do
    user = create(:user)
    buyback(user, insurance_months: 6)
    buyback(user, insurance_months: 120)
    buyback(user, insurance_months: 6)
    buyback(user, lifetime_insurance: true, insurance_months: 36)
    buyback(user, insurance_months: 10_000)
    buyback(user)
    buyback(create(:user), insurance_months: 72)
    sign_in user

    assert_api_response :get, 200 do
      assert_equal({"months" => [120, 6], "lifetime" => true, "none" => false}, parsed_body)
    end
  end

  test "GET /hangar/buybacks/insurance-terms says when pledges have no insurance" do
    user = create(:user)
    buyback(user, insurance_months: 0, details_synced_at: Time.current)
    sign_in user

    assert_api_response :get, 200 do
      assert_equal({"months" => [], "lifetime" => false, "none" => true}, parsed_body)
    end
  end

  test "GET /hangar/buybacks/insurance-terms requires a session or token" do
    assert_api_response :get, 401
  end
end
