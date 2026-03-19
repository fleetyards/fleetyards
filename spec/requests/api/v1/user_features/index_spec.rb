# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/user_features", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:user) { create(:user) }

  before do
    sign_in(user) if user.present?
    Flipper.add("TestFeature")
    FeatureSetting.create!(feature_name: "TestFeature", self_service: true)
  end

  path "/user-features" do
    get("User Feature Flags") do
      operationId "userFeatures"
      tags "UserFeatures"
      produces "application/json"

      security [{
        SessionCookie: [],
        Oauth2: ["profile:write"],
        OpenId: ["profile:write"]
      }]

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/UserFeature"}

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to be_an(Array)
          expect(data.first["name"]).to eq("TestFeature")
        end
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
        let(:user) { nil }
        run_test!
      end
    end
  end

  describe "excludes globally enabled features" do
    before do
      Flipper.enable("TestFeature")
    end

    it "does not return globally enabled features" do
      sign_in(user)
      get "/api/v1/user-features", headers: {"Accept" => "application/json"}
      data = JSON.parse(response.body)
      expect(data).to be_an(Array)
      expect(data).to be_empty
    end
  end
end
