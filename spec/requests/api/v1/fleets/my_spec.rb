# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:member) { create(:user) }
  let(:user) { member }
  let!(:fleet_1) { create(:fleet, admins: [member]) }
  let!(:fleet_2) { create(:fleet, members: [member]) }

  before do
    sign_in(user) if user.present?
  end

  path "/fleets/my" do
    get("Fleets for current User") do
      operationId "myFleets"
      tags "Fleets"
      produces "application/json"

      response(200, "successful") do
        schema type: :array,
          items: {"$ref": "#/components/schemas/Fleet"}

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.size).to eq(2)
          expect(data[0]["id"]).to eq(fleet_1.id)
          expect(data[1]["id"]).to eq(fleet_2.id)
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
