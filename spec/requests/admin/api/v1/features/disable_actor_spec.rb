# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/features", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:features]) }
  let(:id) { "TestFeature" }
  let(:target_user) { create(:user) }

  before do
    sign_in user if user.present?
    Flipper.add("TestFeature")
    Flipper.feature("TestFeature").enable_actor(target_user)
  end

  path "/features/{id}/disable-actor" do
    parameter name: "id", in: :path, schema: {type: :string}, description: "Feature name", required: true

    put("Disable Feature for Actor") do
      operationId "disableAdminFeatureActor"
      tags "Features"
      consumes "application/json"
      produces "application/json"

      parameter name: :body, in: :body, schema: {"$ref": "#/components/schemas/FeatureActorInput"}

      let(:body) { {actor_type: "User", actor_id: target_user.id} }

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Feature"
        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
        let(:id) { "NonExistentFeature" }
        run_test!
      end

      include_examples "admin_auth"
    end
  end
end
