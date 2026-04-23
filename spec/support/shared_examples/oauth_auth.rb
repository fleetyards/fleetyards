# frozen_string_literal: true

# Shared examples for the standard OAuth authentication response pattern.
# Requires `oauth_access_token` and `wrong_scope_access_token` to be defined via let.
# Use inside an rswag operation block (get/post/put/patch/delete):
#
#   include_examples "oauth_auth"
#   include_examples "oauth_auth", success_status: 201
#   include_examples "oauth_auth", success_status: 204

RSpec.shared_examples "oauth_auth" do |success_status: 200|
  response(success_status, "successful with OAuth token", hidden: true) do
    let(:user) { nil }
    let(:Authorization) { "Bearer #{oauth_access_token.token}" }

    run_test!
  end

  response(401, "unauthorized with wrong scope token", hidden: true) do
    schema "$ref": "#/components/schemas/StandardError"

    let(:user) { nil }
    let(:Authorization) { "Bearer #{wrong_scope_access_token.token}" }

    run_test!
  end

  response(401, "unauthorized") do
    schema "$ref": "#/components/schemas/StandardError"

    let(:user) { nil }

    run_test!
  end
end
