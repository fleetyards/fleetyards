# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/sessions", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  fixtures :admin_users

  let(:user) { admin_users :jeanluc }

  before do
    sign_in(user) if user.present?
  end

  path "/sessions" do
    delete("Destroy Session") do
      operationId "destroySession"
      tags "Sessions"
      produces "application/json"

      response(200, "successful") do
        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

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
