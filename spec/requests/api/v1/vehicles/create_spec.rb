# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/vehicles", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:author) { create(:user) }
  let(:user) { author }
  let(:model) { create(:model) }
  let(:input) do
    {
      modelId: model.id
    }
  end

  let(:Authorization) { nil }
  let(:oauth_access_token) do
    create(
      :oauth_access_token,
      resource_owner_id: author.id,
      scopes: ["hangar", "hangar:write"]
    )
  end
  let(:wrong_scope_access_token) do
    create(
      :oauth_access_token,
      resource_owner_id: author.id,
      scopes: ["public"]
    )
  end

  before do
    sign_in(user) if user.present?
  end

  path "/vehicles" do
    post("Create new Vehicle") do
      operationId "createVehicle"
      tags "Vehicles"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/VehicleCreateInput"}, required: true

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(201, "successful") do
        schema "$ref": "#/components/schemas/Vehicle"

        run_test! do
          notification = Notification.find_by(user: author, notification_type: "hangar_create")
          expect(notification).to be_present
          expect(notification.title).to include(model.name)
        end
      end

      response(201, "successful with boughtVia enum value") do
        schema "$ref": "#/components/schemas/Vehicle"

        let(:input) do
          {
            modelId: model.id,
            boughtVia: "pledge_store"
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["boughtVia"]).to eq("pledge_store")
        end
      end

      include_examples "oauth_auth", success_status: 201
    end
  end
end
