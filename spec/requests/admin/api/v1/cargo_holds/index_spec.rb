# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/cargo_holds", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:cargo_holds]) }
  let(:cargo_holds) { create_list(:cargo_hold, 3) }

  before do
    sign_in user if user.present?

    cargo_holds
  end

  path "/cargo-holds" do
    get("Cargo Holds list") do
      operationId "listCargoHolds"
      tags "CargoHolds"

      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: 30}, required: false
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/CargoHoldQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/AdminCargoHolds"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["items"].count).to eq(3)
        end
      end

      include_examples "admin_auth"
    end
  end
end
