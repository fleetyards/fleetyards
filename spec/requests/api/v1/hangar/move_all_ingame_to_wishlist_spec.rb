# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/hangar", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:author) { create(:user) }
  let(:user) { author }
  let(:ingame_vehicles) { create_list(:vehicle, 2, user: author, bought_via: :ingame) }

  let(:Authorization) { nil }
  let(:oauth_access_token) do
    create(
      :oauth_access_token,
      resource_owner_id: author.id,
      scopes: ["hangar", "hangar:write"]
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

    ingame_vehicles
  end

  path "/hangar/move-all-ingame-to-wishlist" do
    put("Move all Ingame Ships from your Hangar to your Wishlist") do
      operationId "moveAllIngameToWishlist"
      tags "Hangar"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(204, "successful") do
        run_test! do
          expect(user.vehicles.where(wanted: true).count).to eq(2)
          expect(user.vehicles.where(wanted: false).count).to eq(0)
        end
      end

      include_examples "oauth_auth", success_status: 204
    end
  end
end
