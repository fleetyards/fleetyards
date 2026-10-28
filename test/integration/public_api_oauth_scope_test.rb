# frozen_string_literal: true

require "test_helper"

# Outside test/integration/api/v1 so it adds nothing to the OpenAPI schema.
class PublicApiOauthScopeTest < ActionDispatch::IntegrationTest
  setup do
    @owner = create(:user, public_hangar: false, friends_hangar: true)
    @friend = create(:user)
    create(:friendship, :accepted, requester: @owner, addressee: @friend)
    create(:vehicle, user: @owner, public: true)
  end

  test "a friends-only hangar is closed to a friend's token without hangar scope" do
    token = create(:oauth_access_token, resource_owner_id: @friend.id, scopes: "public profile:read")

    get "/api/v1/public/hangars/#{@owner.username}", headers: bearer(token)

    assert_response :not_found
  end

  test "a friends-only hangar opens to a friend's token with hangar:read" do
    token = create(:oauth_access_token, resource_owner_id: @friend.id, scopes: "hangar:read")

    get "/api/v1/public/hangars/#{@owner.username}", headers: bearer(token)

    assert_response :success
    assert_equal 1, response.parsed_body["items"].size
  end

  test "a refused token is not read as a signed-in user afterwards" do
    token = create(:oauth_access_token, resource_owner_id: @friend.id, scopes: "public")

    get "/api/v1/public/hangars/embed", params: {usernames: [@owner.username]}, headers: bearer(token)

    assert_response :success
    assert_empty Array(response.parsed_body)
  end

  test "a friend's token without hangar scope does not open a friends-only user card" do
    public_only = create(:oauth_access_token, resource_owner_id: @friend.id, scopes: "public profile:read")
    hangar_reader = create(:oauth_access_token, resource_owner_id: @friend.id, scopes: "hangar:read")

    get "/api/v1/public/users/#{@owner.username}", headers: bearer(public_only)
    assert_response :not_found

    get "/api/v1/public/users/#{@owner.username}", headers: bearer(hangar_reader)
    assert_response :success
  end

  private def bearer(token)
    {"Authorization" => "Bearer #{token.token}"}
  end
end
