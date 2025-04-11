# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/hangar", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:author) { create(:user) }
  let(:user) { author }
  let(:vehicles) { create_list(:vehicle, 3, user: author) }

  before do
    sign_in(user) if user.present?

    vehicles
  end

  path "/hangar/items" do
    get("Your personal Hangar items") do
      operationId "hangarItems"
      tags "Hangar"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {type: :string}

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to be > 0
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
