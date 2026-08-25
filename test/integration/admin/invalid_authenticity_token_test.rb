# frozen_string_literal: true

require "test_helper"

# The admin catch-all funnels every verb into base#index, so a stale token or a
# mismatched Origin reaches the CSRF rescue. That rescue used to render a
# template removed in the Vue 3 migration, which raised MissingTemplate.
class Admin::InvalidAuthenticityTokenTest < ActionDispatch::IntegrationTest
  setup do
    ActionController::Base.allow_forgery_protection = true
  end

  teardown do
    ActionController::Base.allow_forgery_protection = false
  end

  test "a mismatched origin renders the admin shell instead of raising" do
    post "/admin/dashboard", headers: {"HTTP_ORIGIN" => "https://admin.example.test/old"}

    assert_response :unprocessable_entity
  end
end
