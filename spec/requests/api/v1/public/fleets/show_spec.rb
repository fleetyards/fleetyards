# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/public/fleets", type: :openapi, openapi_schema_name: :"v1/schema" do
  let(:user) { create(:user) }
  let(:fleet_admin) { create(:fleet, :with_description, :with_logo, :with_social_links, admins: [user]) }
  let(:fleet_member) { create(:fleet, :with_description, members: [user]) }
  let(:fleet_other) { create(:fleet, :with_description) }
  let(:fleet_hidden) { create(:fleet, :private) }

  before do
    sign_in(user) if user.present?
  end

  path "/public/fleets/{slug}" do
    parameter name: "slug", in: :path, schema: {type: :string}, description: "slug"

    get("Fleet Detail") do
      operationId "publicFleet"
      tags "Fleets"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Fleet"

        let(:slug) { fleet_admin.slug }

        run_test!
      end

      response(200, "successful for member of fleet", hidden: true) do
        schema "$ref": "#/components/schemas/Fleet"

        let(:slug) { fleet_member.slug }

        run_test!
      end

      response(200, "successful for other fleet", hidden: true) do
        schema "$ref": "#/components/schemas/Fleet"

        let(:slug) { fleet_other.slug }

        run_test!
      end

      response(200, "successful without seesion", hidden: true) do
        schema "$ref": "#/components/schemas/Fleet"

        let(:slug) { fleet_other.slug }
        let(:user) { nil }

        run_test!
      end

      response(404, "not found if fleet is not public") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:slug) { fleet_hidden.slug }

        run_test!
      end

      response(404, "not found", hidden: true) do
        schema "$ref": "#/components/schemas/StandardError"

        let(:slug) { "unknown-fleet" }

        run_test!
      end
    end
  end
end
