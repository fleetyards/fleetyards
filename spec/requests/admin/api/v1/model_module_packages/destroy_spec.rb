# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/model_module_packages", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:model_module_packages]) }
  let(:model_module_package) { create(:model_module_package) }
  let(:id) { model_module_package.id }

  before do
    sign_in(user) if user.present?
  end

  path "/model-module-packages/{id}" do
    parameter name: "id", in: :path, description: "Model Module Package id", schema: {type: :string, format: :uuid}

    delete("Destroy Model Module Package") do
      operationId "destroyModelModulePackage"
      tags "ModelModulePackages"
      produces "application/json"

      response(204, "successful") do
        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:id) { SecureRandom.uuid }

        run_test!
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { create(:admin_user, resource_access: []) }

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
