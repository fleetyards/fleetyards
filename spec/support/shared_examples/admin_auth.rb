# frozen_string_literal: true

# Shared examples for the standard admin API 403/401 response pattern.
# Use inside an rswag operation block (get/post/put/patch/delete):
#
#   include_examples "admin_auth", forbidden_user: -> { create(:admin_user, resource_access: []) }
#
# For super_admin-gated endpoints:
#
#   include_examples "admin_auth", forbidden_user: -> { create(:admin_user, super_admin: false) }

RSpec.shared_examples "admin_auth" do |forbidden_user: -> { create(:admin_user, resource_access: []) }|
  response(403, "forbidden") do
    schema "$ref": "#/components/schemas/StandardError"

    let(:user) { instance_exec(&forbidden_user) }

    run_test!
  end

  response(401, "unauthorized") do
    schema "$ref": "#/components/schemas/StandardError"

    let(:user) { nil }

    run_test!
  end
end
