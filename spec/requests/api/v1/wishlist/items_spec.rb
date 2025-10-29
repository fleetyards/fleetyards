# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/wishlist", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:user) { create(:user, wanted_vehicle_count: 2, vehicle_count: 3) }

  before do
    sign_in(user) if user.present?
  end

  path "/wishlist/items" do
    get("Your Wishlist items") do
      operationId "wishlistItems"
      tags "Wishlist"
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
