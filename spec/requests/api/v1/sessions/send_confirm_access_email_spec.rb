# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/sessions", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:user) { create(:user, :oauth_only) }

  before do
    sign_in(user) if user.present?
  end

  path "/sessions/confirm-access-email" do
    post("Send confirm access email") do
      operationId "sendConfirmAccessEmail"
      tags "Sessions"
      produces "application/json"

      security [{
        SessionCookie: []
      }]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/StandardMessage"

        run_test!
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { nil }

        run_test!
      end

      response(403, "forbidden - user has password") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { create(:user, password: "enterprise", password_set_manually: true) }

        run_test!
      end
    end
  end
end
