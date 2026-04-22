# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/fleets", type: :openapi, openapi_schema_name: :"v1/schema" do
  let(:admin) { create(:user, :with_rsi_handle) }
  let(:member) { create(:user) }
  let(:user) { admin }
  let(:fleet) { create(:fleet, :with_description, :with_logo, :with_background_image, :with_social_links, admins: [admin], members: [member]) }
  let(:fleet_other) { create(:fleet) }
  let(:slug) { fleet.slug }

  let(:Authorization) { nil }
  let(:oauth_access_token) do
    create(
      :oauth_access_token,
      resource_owner_id: admin.id,
      scopes: ["fleet", "fleet:read"]
    )
  end
  let(:wrong_scope_access_token) do
    create(
      :oauth_access_token,
      resource_owner_id: admin.id,
      scopes: ["public"]
    )
  end

  before do
    sign_in(user) if user.present?
  end

  path "/fleets/{slug}" do
    parameter name: "slug", in: :path, type: :string, description: "slug"

    get("Fleet Detail") do
      operationId "fleet"
      tags "Fleets"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Fleet"

        context "for admin" do
          run_test!
        end

        context "for member" do
          let(:user) { member }

          run_test!
        end
      end

      include_examples "oauth_auth"

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:slug) { fleet_other.slug }

        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:slug) { "unknown-fleet" }

        run_test!
      end
    end
  end
end
