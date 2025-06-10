# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/hangar", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:user) { create(:user, vehicle_count: 2) }

  before do
    sign_in(user) if user.present?
  end

  path "/hangar" do
    delete("Clear your personal Hangar") do
      operationId "destroyHangar"
      tags "Hangar"
      produces "application/json"

      response(204, "successful") do
        run_test! do
          expect(user.vehicles.where(wanted: false).count).to eq(0)
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
