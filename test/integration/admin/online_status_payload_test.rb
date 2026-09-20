# frozen_string_literal: true

require "test_helper"

# Outside test/integration/admin/api/v1 on purpose — see the note on the public
# twin. What matters here is that neither the flag nor the user's own switch
# stands between an admin and the truth.
class Admin::OnlineStatusPayloadTest < ActionDispatch::IntegrationTest
  setup do
    UserPresence.reset!

    @admin_user = create(:admin_user, super_admin: true)
    @user = create(:user, show_online_status: false)

    UserPresence.connect(@user.id, "tab-1")

    sign_in @admin_user, scope: :admin_user
  end

  teardown do
    UserPresence.reset!
  end

  test "an admin sees a connected user as online despite the switch and the flag" do
    get "/admin/api/v1/users", params: {q: {search: @user.username}}, as: :json

    assert_equal 200, response.status

    row = JSON.parse(response.body)["items"].find { |item| item["id"] == @user.id }

    assert_equal true, row["online"]
  end
end
