# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FriendshipsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/friends" do
    get("Friends") do
      operationId "friends"
      tags "Friends"
      produces "application/json"

      parameter name: "state", in: :query, required: false,
        schema: ::V1::Schemas::Enums::RelationshipStateEnum,
        description: "Which state to list, as this user sees it. Defaults to accepted."
      parameter name: "direction", in: :query, required: false,
        schema: ::V1::Schemas::Enums::RelationshipDirectionEnum,
        description: "Limit to requests this user sent, or ones they were sent"
      parameter name: "page", in: :query, required: false, schema: {type: :integer}
      parameter name: "limit", in: :query, required: false, schema: {type: :integer}

      security [
        {SessionCookie: []},
        {Oauth2: ["profile:read"]},
        {OpenId: ["profile:read"]}
      ]

      response(200, "successful") { schema ::V1::Schemas::FriendshipsList }
      response(401, "unauthorized") { schema ::Shared::V1::Schemas::StandardError }
      response(403, "forbidden") { schema ::Shared::V1::Schemas::StandardError }
    end

    post("Send Friend Request") do
      operationId "createFriendship"
      tags "Friends"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::FriendshipCreateInput

      security [
        {SessionCookie: []},
        {Oauth2: ["profile:write"]},
        {OpenId: ["profile:write"]}
      ]

      response(201, "created") { schema ::V1::Schemas::Friendship }
      response(400, "bad request") { schema ::Shared::V1::Schemas::ValidationError }
      response(401, "unauthorized") { schema ::Shared::V1::Schemas::StandardError }
      response(403, "forbidden") { schema ::Shared::V1::Schemas::StandardError }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  api_path "/friends/pending-count" do
    get("Pending friend request count") do
      operationId "friendsPendingCount"
      tags "Friends"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["profile:read"]},
        {OpenId: ["profile:read"]}
      ]

      response(200, "successful") { schema ::V1::Schemas::RelationshipPendingCount }
      response(401, "unauthorized") { schema ::Shared::V1::Schemas::StandardError }
      response(403, "forbidden") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  setup do
    Flipper.enable("friends")

    @user = create(:user)
    @other = create(:user)
  end

  test "GET lists accepted friends by default" do
    friend = create(:user)
    create(:friendship, :accepted, requester: @user, addressee: friend)
    create(:friendship, requester: @user, addressee: @other)
    sign_in @user

    assert_api_response :get, 200, api_path: "/friends" do
      assert_equal 1, parsed_body["items"].count
      assert_equal friend.username, parsed_body["items"].first.dig("user", "username")
      assert_equal "accepted", parsed_body["items"].first["state"]
    end
  end

  test "GET lists requests in each direction" do
    incoming = create(:user)
    create(:friendship, requester: incoming, addressee: @user)
    create(:friendship, requester: @user, addressee: @other)
    sign_in @user

    assert_api_response :get, 200, api_path: "/friends", params: {state: "pending", direction: "incoming"} do
      assert_equal [incoming.username], parsed_body["items"].map { |row| row.dig("user", "username") }
      assert_equal ["incoming"], parsed_body["items"].map { |row| row["direction"] }
    end

    assert_api_response :get, 200, api_path: "/friends", params: {state: "pending", direction: "outgoing"} do
      assert_equal [@other.username], parsed_body["items"].map { |row| row.dig("user", "username") }
      assert_equal ["outgoing"], parsed_body["items"].map { |row| row["direction"] }
    end
  end

  # The list has to keep the same secret `state_for` does. A request the other
  # side ignored is gone from their inbox and unchanged in the sender's.
  test "GET still lists a request that was ignored as pending" do
    create(:friendship, :ignored, requester: @user, addressee: @other)
    sign_in @user

    assert_api_response :get, 200, api_path: "/friends", params: {state: "pending", direction: "outgoing"} do
      assert_equal 1, parsed_body["items"].count
      assert_equal "pending", parsed_body["items"].first["state"]
    end
  end

  test "GET does not show the ignored request in the recipient's pending list" do
    create(:friendship, :ignored, requester: @other, addressee: @user)
    sign_in @user

    assert_api_response :get, 200, api_path: "/friends", params: {state: "pending", direction: "incoming"} do
      assert_empty parsed_body["items"]
    end

    assert_api_response :get, 200, api_path: "/friends", params: {state: "ignored"} do
      assert_equal 1, parsed_body["items"].count
    end
  end

  # `api_path` on every one of these: two collection paths now answer GET in
  # this class, and the helper cannot tell which one a bare call means.
  test "GET pending-count counts only what is waiting on the reader" do
    create(:friendship, requester: @other, addressee: @user)
    create(:friendship, requester: create(:user), addressee: @user)
    create(:friendship, requester: @user, addressee: create(:user))
    create(:friendship, :accepted, requester: @user, addressee: create(:user))
    create(:friendship, :ignored, requester: create(:user), addressee: @user)
    sign_in @user

    assert_api_response :get, 200, api_path: "/friends/pending-count" do
      assert_equal 2, parsed_body["count"]
    end
  end

  test "GET pending-count without a session is unauthorized" do
    assert_api_response :get, 401, api_path: "/friends/pending-count"
  end

  test "GET pending-count is forbidden with the feature off" do
    Flipper.disable("friends")
    sign_in @user

    assert_api_response :get, 403, api_path: "/friends/pending-count"
  end

  test "GET without a session is unauthorized" do
    assert_api_response :get, 401, api_path: "/friends"
  end

  test "GET is forbidden with the feature off" do
    Flipper.disable("friends")
    sign_in @user

    assert_api_response :get, 403, api_path: "/friends"
  end

  test "POST sends a request" do
    sign_in @user

    assert_api_response :post, 201, body: {username: @other.username} do
      assert_equal "pending", parsed_body["state"]
      assert_equal "outgoing", parsed_body["direction"]
      assert_equal @other.username, parsed_body.dig("user", "username")
    end
  end

  test "POST accepts a request the other side already sent" do
    create(:friendship, requester: @other, addressee: @user)
    sign_in @user

    assert_api_response :post, 201, body: {username: @other.username} do
      assert_equal "accepted", parsed_body["state"]
    end

    assert_equal 1, Friendship.count
  end

  # Indistinguishable from the plain case above, which is the requirement.
  test "POST to somebody who ignored you answers exactly as a fresh request does" do
    create(:friendship, :ignored, requester: @user, addressee: @other)
    sign_in @user

    assert_api_response :post, 201, body: {username: @other.username} do
      assert_equal "pending", parsed_body["state"]
      assert_equal "outgoing", parsed_body["direction"]
    end

    assert Friendship.between(@user, @other).ignored?
  end

  test "POST to yourself is refused" do
    sign_in @user

    assert_api_response :post, 400, body: {username: @user.username}
  end

  test "POST to somebody who is already a friend is refused" do
    create(:friendship, :accepted, requester: @user, addressee: @other)
    sign_in @user

    assert_api_response :post, 400, body: {username: @other.username}
  end

  test "POST to an unknown username is a 404" do
    sign_in @user

    assert_api_response :post, 404, body: {username: "nobody-by-that-name"}
  end

  test "POST without a session is unauthorized" do
    assert_api_response :post, 401, body: {username: @other.username}
  end
end
