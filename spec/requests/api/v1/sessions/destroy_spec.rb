# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/sessions", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:user) { create(:user) }

  before do
    sign_in(user) if user.present?
  end

  path "/sessions" do
    delete("Destroy Session") do
      operationId "destroySession"
      tags "Sessions"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/StandardMessage"

        run_test!
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { nil }

        run_test!
      end
    end
  end
end
