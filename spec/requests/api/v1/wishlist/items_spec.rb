# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/wishlist", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:author) { create(:user, wanted_vehicle_count: 2, vehicle_count: 3) }
  let(:user) { author }

  let(:Authorization) { nil }
  let(:oauth_access_token) do
    create(
      :oauth_access_token,
      resource_owner_id: author.id,
      scopes: ["hangar", "hangar:read"]
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
  end

  path "/wishlist/items" do
    get("Your Wishlist items") do
      operationId "wishlistItems"
      tags "Wishlist"
      produces "application/json"

      security [
        { SessionCookie: [] },
        { Oauth2: ["hangar", "hangar:read"] },
        { OpenId: ["hangar", "hangar:read"] }
      ]

      response(200, "successful") do
        schema type: :array, items: {type: :string}

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to be > 0
        end
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

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { nil }

        run_test!
      end
    end
  end
end
