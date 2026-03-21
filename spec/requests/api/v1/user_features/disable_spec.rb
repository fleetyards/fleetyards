# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/user_features", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:author) { create(:user) }
  let(:user) { author }
  let(:id) { "TestFeature" }

  let(:Authorization) { nil }
  let(:oauth_access_token) do
    create(
      :oauth_access_token,
      resource_owner_id: author.id,
      scopes: ["profile:write"]
    )
  end
  let(:wrong_scope_access_token) do
    create(
      :oauth_access_token,
      resource_owner_id: author.id,
      scopes: ["public"]
    )
  end

  before do
    sign_in(user) if user.present?
    Flipper.add("TestFeature")
    FeatureSetting.create!(feature_name: "TestFeature", self_service: true)
    Flipper.feature("TestFeature").enable_actor(user) if user.present?
  end

  path "/user-features/{id}/disable" do
    parameter name: "id", in: :path, schema: {type: :string}, description: "Feature name", required: true

    put("Disable User Feature") do
      operationId "disableUserFeature"
      tags "UserFeatures"
      produces "application/json"

      security [
        { SessionCookie: [] },
        { Oauth2: ["profile:write"] },
        { OpenId: ["profile:write"] }
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/UserFeature"
        run_test!
      end

      response(200, "successful with OAuth token") do
        let(:user) { nil }
        let(:Authorization) { "Bearer #{oauth_access_token.token}" }

        run_test!
      end

      response(401, "unauthorized with wrong scope token") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { nil }
        let(:Authorization) { "Bearer #{wrong_scope_access_token.token}" }

        run_test!
      end

      response(403, "forbidden") do
        schema type: :object, properties: {code: {type: :string}, message: {type: :string}}
        let(:id) { "NonSelfServiceFeature" }

        before do
          Flipper.add("NonSelfServiceFeature")
        end

        run_test!
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
        let(:user) { nil }
        run_test!
      end
    end
  end
end
