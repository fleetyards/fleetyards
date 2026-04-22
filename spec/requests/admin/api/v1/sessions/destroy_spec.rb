# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/sessions", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user) }

  before do
    sign_in(user) if user.present?
  end

  path "/sessions" do
    delete("Destroy Session") do
      operationId "destroySession"
      tags "Sessions"
      produces "application/json"

      response(200, "successful") do
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
