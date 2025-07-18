# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/public/hangars/stats", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:user) { create(:user, vehicle_count: 2, wanted_vehicle_count: 3) }
  let(:username) { user.username }

  path "/public/hangars/{username}/stats" do
    parameter name: "username", in: :path, type: :string, description: "username"

    get("Public Hangar Stats") do
      operationId "publicHangarStats"
      tags "PublicHangarStats"
      produces "application/json"

      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/HangarQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/HangarStatsPublic"

        context "with public_wishlist enabled" do
          let(:user) { create(:user, vehicle_count: 2, wanted_vehicle_count: 3, public_wishlist: true) }

          it "includes wishlist_total in response" do
            get "/api/v1/public/hangars/#{username}/stats"
            expect(response.status).to eq(200)

            response_data = JSON.parse(response.body)
            expect(response_data["wishlist_total"]).to eq(3)
          end
        end

        context "with public_wishlist disabled" do
          let(:user) { create(:user, vehicle_count: 2, wanted_vehicle_count: 3, public_wishlist: false) }

          it "does not include wishlist_total in response" do
            get "/api/v1/public/hangars/#{username}/stats"
            expect(response.status).to eq(200)

            response_data = JSON.parse(response.body)
            expect(response_data["wishlist_total"]).to be_nil
          end
        end

        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:username) { "non-existent-username" }

        run_test!
      end
    end
  end
end
