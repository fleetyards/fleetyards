# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "api/v1/hangar", type: :openapi, openapi_schema_name: :"v1/schema" do
  let(:author) { create(:user, vehicle_count: 2) }
  let(:user) { author }

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

  path "/hangar" do
    delete("Clear your personal Hangar") do
      operationId "destroyHangar"
      tags "Hangar"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(204, "successful") do
        run_test! do
          expect(user.vehicles.where(wanted: false).count).to eq(0)
        end
      end

      include_examples "oauth_auth", success_status: 204
    end
  end
end
