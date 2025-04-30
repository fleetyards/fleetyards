# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/hangar", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:author) { create(:user, wanted_vehicle_count: 2) }
  let(:user) { author }
  let(:vehicles) { create_list(:vehicle, 3, user: author) }

  before do
    sign_in(user) if user.present?

    vehicles
  end

  path "/hangar/export" do
    get("Export your personal Hangar") do
      operationId "hangarExport"
      tags "Hangar"
      produces "application/json"

      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/HangarQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema type: :array,
          items: {"$ref": "#/components/schemas/VehicleExport"}

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to be > 0
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
