# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/hangars/groups", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:user) { create(:user, public_hangar: true) }
  let(:username) { user.username }

  before do
    create_list(:hangar_group, 3, :public, user: user)
  end

  path "/public/hangars/{username}/groups" do
    parameter name: "username", in: :path, type: :string, description: "Username", required: true

    get("HangarGroup list") do
      operationId "publicHangarGroups"
      tags "PublicHangarGroups"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/HangarGroupPublic"}

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.size).to eq(3)
        end
      end
    end
  end
end
