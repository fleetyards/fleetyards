# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/users", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:users]) }

  let!(:users) { create_list(:user, 6) }

  before do
    sign_in(user) if user.present?
  end

  path "/users/options" do
    get("User Options") do
      operationId "userOptions"
      tags "Users"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: :q, in: :query, schema: {type: :object, "$ref": "#/components/schemas/UserQuery"}, required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/UserOptions"

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to eq(6)
          expect(items.first.keys).to match_array(%w[id username])
        end
      end

      include_examples "admin_auth"
    end
  end
end
