# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/hangar_groups", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :hangar_groups, :users

  let(:user) { nil }
  let(:hangar_group) { hangar_groups :hangargroupone }

  before do
    sign_in(user) if user.present?
  end

  path "/hangar-groups/{id}" do
    parameter name: "id", in: :path, description: "HangarGroup ID", schema: {type: :string, format: :uuid}, required: true

    put("HangarGroup Update") do
      operationId "update"
      tags "HangarGroups"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/HangarGroupUpdateInput"}, required: true

      response(200, "successful") do
        schema "$ref": "#/components/schemas/HangarGroupMinimal"

        let(:id) { hangar_group.id }
        let(:user) { users :data }
        let(:input) do
          {
            name: "Hangar Group One Test"
          }
        end

        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["name"]).to eq("Hangar Group One Test")
        end
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:id) { SecureRandom.uuid }
        let(:user) { users :data }
        let(:input) { nil }

        run_test!
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:id) { hangar_group.id }
        let(:input) { nil }

        run_test!
      end
    end
  end
end
