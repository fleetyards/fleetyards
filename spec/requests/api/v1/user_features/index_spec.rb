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
end
