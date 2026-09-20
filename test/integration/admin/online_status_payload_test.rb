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

    # Explicit, because that is half of what this asserts: the admin view reads
    # the store directly, so the answer must not depend on the rollout either.
    Flipper.disable(:online_status)

    sign_in @admin_user, scope: :admin_user
  end

  teardown do
    UserPresence.reset!
  end

  test "an admin sees a connected user as online despite the switch and the flag" do
    refute Flipper.enabled?(:online_status), "the flag must be off for this to prove anything"

    get "/admin/api/v1/users", params: {q: {search: @user.username}}, as: :json

    assert_equal 200, response.status

    row = JSON.parse(response.body)["items"].find { |item| item["id"] == @user.id }

    assert_equal true, row["online"]
  end
end
