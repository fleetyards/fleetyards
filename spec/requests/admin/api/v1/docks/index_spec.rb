# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/docks", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:docks]) }
  let(:docks) { create_list(:dock, 3) }

  before do
    sign_in user if user.present?

    docks
  end

  path "/docks" do
    get("Docks list") do
      operationId "docks"
      tags "Docks"

      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: Dock.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/DockQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Docks"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["items"].count).to eq(3)
        end
      end

      include_examples "admin_auth"
    end
  end
end
