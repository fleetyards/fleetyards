# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/users", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:author) { create(:user) }
  let(:user) { author }

  let(:Authorization) { nil }
  let(:oauth_access_token) do
    create(
      :oauth_access_token,
      resource_owner_id: author.id,
      scopes: ["public"]
    )
  end

  before do
    sign_in(user) if user.present?
  end

  path "/users/me" do
    delete("Destroy Account") do
      operationId "destroyAccount"
      tags "Users"

      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: []},
        {OpenId: []}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/StandardMessage"

        run_test!
      end

      response(200, "successful with OAuth token") do
        let(:user) { nil }
        let(:Authorization) { "Bearer #{oauth_access_token.token}" }

        run_test!
      end

      response(200, "successful when sole fleet admin") do
        schema "$ref": "#/components/schemas/StandardMessage"

        before do
          create(:fleet, admins: [author])
        end

        run_test!
      end

      response(400, "blocked by permanent fleet role") do
        schema "$ref": "#/components/schemas/ValidationError"

        before do
          other_user = create(:user)
          create(:fleet, admins: [author], members: [other_user])
        end

        run_test!
      end

      response(401, "bad request") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { nil }

        run_test!
      end
    end
  end
end
