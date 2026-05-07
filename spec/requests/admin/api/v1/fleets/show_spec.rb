# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/fleets", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:fleets]) }
  let(:fleet) { create(:fleet) }
  let(:id) { fleet.id }

  before do
    sign_in(user) if user.present?
  end

  path "/fleets/{id}" do
    parameter name: "id", in: :path, description: "Fleet id", schema: {type: :string, format: :uuid}

    get("Fleet Detail") do
      operationId "fleet"
      tags "Fleets"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Fleet"

        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:id) { SecureRandom.uuid }

        run_test!
      end

      include_examples "admin_auth"
    end
  end
end
