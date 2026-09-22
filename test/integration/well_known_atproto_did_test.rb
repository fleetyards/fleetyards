# frozen_string_literal: true

require "test_helper"

# Bluesky verifies the `fleetyards.net` handle by fetching this path and reading
# the DID it answers with. A static file rather than a route: the frontend
# catch-all answers every unmatched path with the app shell, so before the file
# existed the resolver got HTML back.
class WellKnownAtprotoDidTest < ActionDispatch::IntegrationTest
  test "GET .well-known/atproto-did answers the account's DID" do
    get "/.well-known/atproto-did"

    assert_response :success
    assert_equal "did:plc:ekvtnyzbkml5bg2jqblbiqds", response.body.strip
  end
end
