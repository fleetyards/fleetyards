# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:admin) { create(:user) }
  let(:member) { create(:user) }
  let(:user) { admin }
  let(:fleet) { create(:fleet, admins: [admin], members: [member]) }
  let(:fleet_other) { create(:fleet) }
  let(:slug) { fleet.slug }

  before do
    sign_in(user) if user.present?
  end

  path "/fleets/{slug}" do
    parameter name: "slug", in: :path, type: :string, description: "slug"

    get("Fleet Detail") do
      operationId "fleet"
      tags "Fleets"
      produces "application/json"

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

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { nil }

        run_test!
      end
    end
  end
end
