# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/users", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:admin) { create(:admin_user, resource_access: [:users]) }
  let(:user) { create(:user) }
  let(:id) { user.id }

  before do
    sign_in(admin) if admin.present?
  end

  path "/users/{id}/send-password-reset" do
    parameter name: "id", in: :path, description: "User id", schema: {type: :string, format: :uuid}

    post("Send Password Reset") do
      operationId "sendUserPasswordReset"
      tags "Users"
      produces "application/json"

      response(204, "no content") do
        before do
          Sidekiq::Testing.inline!
        end

        after do
          Sidekiq::Testing.fake!
        end

        run_test! do
          expect(ActionMailer::Base.deliveries.count).to eq(1)
        end
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:id) { SecureRandom.uuid }

        run_test!
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:admin) { create(:admin_user, resource_access: []) }

        run_test!
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:admin) { nil }

        run_test!
      end
    end
  end
end
