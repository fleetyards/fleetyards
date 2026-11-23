# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarPaintsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/hangar/paints" do
    get("The paints you own") do
      operationId "hangarPaints"
      tags "Hangar"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:read"]},
        {OpenId: ["hangar", "hangar:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Hangar::HangarPaintsList
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @user = create(:user)
    @model = create(:model)
    @recorded, @pledged, @wishlist, @loaner, @others = create_list(:model_paint, 5, model: @model)

    paint_on(create(:vehicle, user: @user, model: @model), @recorded)
    paint_on(create(:vehicle, user: @user, model: @model, wanted: true), @wishlist)
    paint_on(create(:vehicle, user: @user, model: @model, loaner: true), @loaner)
    paint_on(create(:vehicle, model: @model), @others)

    item = create(:hangar_pledge_item, user: @user)
    HangarPledgeItemModelPaint.create!(hangar_pledge_item: item, model_paint: @pledged)
  end

  def paint_on(vehicle, paint)
    VehiclePaint.create!(vehicle:, model_paint: paint)
  end

  test "GET /hangar/paints returns the paints on your ships and from your pledges" do
    sign_in @user

    assert_api_response :get, 200 do
      assert_equal [@recorded.id, @pledged.id].sort, parsed_body.sort
    end
  end

  test "GET /hangar/paints returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /hangar/paints with OAuth bearer token" do
    assert_api_response :get, 200, headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:read"])
  end
end
