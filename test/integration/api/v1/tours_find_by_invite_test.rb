# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ToursFindByInviteTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/tours/find-by-invite/{token}" do
    parameter name: "token", in: :path, schema: {type: :string}

    get("Preview a tour behind an invite link") do
      operationId "findTourByInvite"
      tags "Tours"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["user"]},
        {OpenId: ["user"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Payouts::Tour
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("tour_payouts")
    @organiser = create(:user)
    @outsider = create(:user)
    @tour = create(:tour, created_by: @organiser)
  end

  # Deliberately outside the relation scope: someone holding the link has not
  # joined yet, so they are not on the tour and could not otherwise see it.
  test "GET shows the tour to someone who has not joined" do
    sign_in @outsider

    assert_api_response :get, 200, path_params: {token: @tour.invite_token} do
      assert_equal @tour.title, parsed_body["title"]
    end
  end

  test "GET withholds the invite token from the viewer" do
    sign_in @outsider

    assert_api_response :get, 200, path_params: {token: @tour.invite_token} do
      assert_nil parsed_body["inviteToken"]
    end
  end

  test "GET returns 404 for an unknown token" do
    sign_in @outsider

    assert_api_response :get, 404, path_params: {token: "deadbeef"}
  end

  test "GET returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {token: @tour.invite_token}
  end
end
