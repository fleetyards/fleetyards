# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/users", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  fixtures :all

  let(:user) { admin_users :jeanluc }

  before do
    sign_in(user) if user.present?
  end

  path "/admin_users/me" do
    get("My Data") do
      operationId "me"
      tags "AdminUsers"
      produces "application/json"

      response(200, "successful") do
        schema "$ref" => "#/components/schemas/AdminUser"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["username"]).to eq("jeanluc")
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
