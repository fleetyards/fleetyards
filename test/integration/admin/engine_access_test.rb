# frozen_string_literal: true

require "test_helper"

class Admin::EngineAccessTest < ActionDispatch::IntegrationTest
  test "an admin with the maintenance privilege opens maintenance tasks" do
    sign_in create(:admin_user, resource_access: ["maintenance"]), scope: :admin_user

    get "/admin/maintenance_tasks"

    assert_response :success
  end
end
