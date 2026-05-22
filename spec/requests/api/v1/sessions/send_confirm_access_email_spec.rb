# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/sessions", type: :openapi, openapi_schema_name: :"v1/schema" do
  let(:user) { create(:user, :oauth_only) }

  before do
    sign_in(user) if user.present?
  end

  path "/sessions/confirm-access-email" do
    post("Send confirm access email with code") do
      operationId "sendConfirmAccessEmail"
      tags "Sessions"
      produces "application/json"

      security [{
        SessionCookie: []
      }]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ConfirmAccessEmailResponse"

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
