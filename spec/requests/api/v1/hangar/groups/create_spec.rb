# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/hangar/groups", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :users

  let(:user) { nil }

  before do
    sign_in(user) if user.present?
  end

  path "/hangar/groups" do
    post("HangarGroup create") do
      operationId "create"
      tags "HangarGroups"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/HangarGroupCreateInput"}, required: true

      response(201, "successful") do
        schema "$ref": "#/components/schemas/HangarGroup"

        let(:user) { users :data }
        let(:input) do
          {
            name: "Hangar Group One Test",
            color: "#000000"
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

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:input) { nil }

        run_test!
      end
    end
  end
end
