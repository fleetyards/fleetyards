# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/wishlist", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:user) { create(:user, wanted_vehicle_count: 2, vehicle_count: 3) }

  before do
    sign_in(user) if user.present?
  end

  path "/wishlist" do
    delete("Clear your Wishlist") do
      operationId "destroyWishlist"
      tags "Wishlist"
      produces "application/json"

      response(204, "successful") do
        run_test! do
          expect(user.vehicles.where(wanted: true).count).to eq(0)
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
