# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/hangars/groups", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :hangar_groups, :users

  let(:user) { users :data }

  path "/public/hangars/{username}/groups" do
    parameter name: "username", in: :path, type: :string, description: "Username", required: true

    get("HangarGroup list") do
      operationId "publicHangarGroups"
      tags "PublicHangarGroups"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/HangarGroupPublic"}

        let(:username) { user.username }

        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.size).to eq(1)
        end
      end
    end
  end
end
