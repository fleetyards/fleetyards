# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/hangar/stats", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:author) { create(:user, wanted_vehicle_count: 2) }
  let(:user) { author }
  let(:vehicles) { create_list(:vehicle, 3, user: author) }

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

    vehicles
  end

  path "/hangar/stats" do
    get("Your Hangar Stats") do
      operationId "hangarStats"
      tags "HangarStats"
      produces "application/json"

      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/HangarQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:read"]},
        {OpenId: ["hangar", "hangar:read"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/HangarStats"

        run_test!
      end

      include_examples "oauth_auth"
    end
  end
end
