# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/hangar/groups", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:author) { create(:user) }
  let(:user) { author }
  let(:hangar_groups) { create_list(:hangar_group, 3, user: author) }

  before do
    sign_in(user) if user.present?

    hangar_groups
  end

  path "/hangar/groups" do
    get("HangarGroup list") do
      operationId "hangarGroups"
      tags "HangarGroups"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/HangarGroup"}

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.size).to eq(3)
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
