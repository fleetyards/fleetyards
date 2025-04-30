# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:admin) { create(:user) }
  let(:member) { create(:user) }
  let(:fleet) { create(:fleet, admins: [admin], members: [member]) }
  let(:user) { admin }
  let(:slug) { fleet.slug }

  before do
    sign_in(user) if user.present?
  end

  path "/fleets/{slug}" do
    parameter name: "slug", in: :path, type: :string, description: "slug"

    delete("Destroy Fleet") do
      operationId "destroyFleet"
      tags "Fleets"
      produces "application/json"

      response(204, "successful") do
        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:slug) { "unknown-model" }

        run_test!
      end

      response(403, "forbidden") do
        description "You are not the owner of this Fleet"
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { member }

        run_test!
      end

      response(403, "forbidden") do
        description "You are not the owner of this Fleet"
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { create(:user) }

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
