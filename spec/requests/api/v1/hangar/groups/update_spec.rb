# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/hangar/groups", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:author) { create(:user) }
  let(:user) { author }
  let(:hangar_group) { create(:hangar_group, user: author) }
  let(:id) { hangar_group.id }

  let(:input) do
    {
      name: "Hangar Group One Test"
    }
  end

  before do
    sign_in(user) if user.present?
  end

  path "/hangar/groups/{id}" do
    parameter name: "id", in: :path, description: "HangarGroup ID", schema: {type: :string, format: :uuid}, required: true

    put("HangarGroup Update") do
      operationId "updateHangarGroup"
      tags "HangarGroups"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/HangarGroupUpdateInput"}, required: true

      response(200, "successful") do
        schema "$ref": "#/components/schemas/HangarGroup"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["name"]).to eq("Hangar Group One Test")
        end
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:id) { SecureRandom.uuid }

        run_test!
      end

      response(403, "forbidden") do
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
