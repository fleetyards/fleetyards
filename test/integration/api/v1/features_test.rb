# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FeaturesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/features" do
    get("Feature Flags for User") do
      operationId "features"
      tags "Features"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {type: :string}
      end
    end
  end

  setup do
    Flipper.enable("NewFeature")
  end

  test "GET /features returns the enabled feature flags" do
    assert_api_response :get, 200 do
      assert_equal ["NewFeature"], parsed_body
    end
  end

  test "GET /features includes a flag enabled for the signed-in user" do
    user = create(:user)
    Flipper.add("PersonalFeature")
    Flipper.enable_actor("PersonalFeature", user)
    sign_in user

    assert_api_response :get, 200 do
      assert_includes parsed_body, "PersonalFeature"
    end
  end

  test "GET /features omits a flag enabled only for one of the user's fleets" do
    user = create(:user)
    fleet = create(:fleet, admins: [user])
    Flipper.add("FleetWideFeature")
    Flipper.enable_actor("FleetWideFeature", fleet)
    sign_in user

    assert_api_response :get, 200 do
      assert_not_includes parsed_body, "FleetWideFeature",
        "a fleet's flags belong to that fleet's payload, or they leak onto every other fleet's page"
    end
  end
end
