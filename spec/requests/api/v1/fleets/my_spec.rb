# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:member) { create(:user) }
  let(:user) { member }
  let!(:fleet_1) { create(:fleet, admins: [member]) }
  let!(:fleet_2) { create(:fleet, members: [member]) }

  let(:Authorization) { nil }
  let(:oauth_access_token) do
    create(
      :oauth_access_token,
      resource_owner_id: member.id,
      scopes: ["fleet", "fleet:read"]
    )
  end
  let(:wrong_scope_access_token) do
    create(
      :oauth_access_token,
      resource_owner_id: member.id,
      scopes: ["public"]
    )
  end

  before do
    sign_in(user) if user.present?
  end

  path "/fleets/my" do
    get("Fleets for current User") do
      operationId "myFleets"
      tags "Fleets"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema type: :array,
          items: {"$ref": "#/components/schemas/Fleet"}

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.size).to eq(2)
          expect(data.map { |f| f["id"] }).to match_array([fleet_1.id, fleet_2.id])
        end
      end

      include_examples "oauth_auth"
    end
  end
end
