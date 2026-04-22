# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/components", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:components]) }
  let(:component) { create(:component) }
  let(:id) { component.id }

  before do
    sign_in(user) if user.present?
  end

  path "/components/{id}" do
    parameter name: "id", in: :path, description: "Component id", schema: {type: :string, format: :uuid}

    delete("Destroy Component") do
      operationId "destroyComponent"
      tags "Components"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Component"

        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:id) { SecureRandom.uuid }

        run_test!
      end

      include_examples "admin_auth"
    end
  end
end
