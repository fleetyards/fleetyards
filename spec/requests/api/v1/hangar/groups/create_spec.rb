# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/hangar/groups", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:user) { create(:user) }
  let(:input) do
    {
      name: "Hangar Group One Test",
      color: "#000000"
    }
  end

  before do
    sign_in(user) if user.present?
  end

  path "/hangar/groups" do
    post("HangarGroup create") do
      operationId "createHangarGroup"
      tags "HangarGroups"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/HangarGroupCreateInput"}, required: true

      response(201, "successful") do
        schema "$ref": "#/components/schemas/HangarGroup"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["name"]).to eq("Hangar Group One Test")
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
