# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/wishlist", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  let(:user) { nil }

  before do
    host! "api.fleetyards.test"

    sign_in(user) if user.present?
  end

  path "/wishlist" do
    delete("Clear your Wishlist") do
      operationId "destroy"
      tags "Wishlist"
      produces "application/json"

      response(204, "successful") do
        let(:user) { users :data }

        run_test!
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        run_test!
      end
    end
  end
end
