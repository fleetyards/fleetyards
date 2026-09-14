# frozen_string_literal: true

require "test_helper"

# The invite list became a view of the members page. The old path is live --
# mail already sent carries it, and people have shared it -- so it resolves
# from the server rather than by loading the app and bouncing.
class FleetMemberInvitesRedirectTest < ActionDispatch::IntegrationTest
  test "GET the old invites path lands on the members page's invite view" do
    get "/fleets/black-sun/members/invites"

    assert_response :moved_permanently
    assert_equal "http://www.example.com/fleets/black-sun/members/?view=invites",
      response.location
  end

  test "it keeps what the link carried" do
    get "/fleets/black-sun/members/invites?page=2"

    assert_response :moved_permanently
    assert_equal "http://www.example.com/fleets/black-sun/members/?view=invites&page=2",
      response.location
  end
end
