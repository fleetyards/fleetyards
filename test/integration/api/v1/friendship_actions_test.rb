# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FriendshipActionsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  # Three member paths share PUT, and openapi-ruby matches on verb, path params
  # and status -- none of which tell them apart. Every PUT assertion names one.
  ACCEPT_PATH = "/friends/{username}/accept"
  DECLINE_PATH = "/friends/{username}/decline"
  IGNORE_PATH = "/friends/{username}/ignore"

  WRITE_SECURITY = [
    {SessionCookie: []},
    {Oauth2: ["profile:write"]},
    {OpenId: ["profile:write"]}
  ].freeze

  api_path "/friends/{username}" do
    parameter name: "username", in: :path, schema: {type: :string}, description: "The other user's username"

    get("Friendship") do
      operationId "friendship"
      tags "Friends"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["profile:read"]},
        {OpenId: ["profile:read"]}
      ]

      response(200, "successful") { schema ::V1::Schemas::Friendship }
      response(401, "unauthorized") { schema ::Shared::V1::Schemas::StandardError }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end

    delete("Withdraw a request, or end a friendship") do
      operationId "destroyFriendship"
      tags "Friends"

      security WRITE_SECURITY

      response(204, "removed")
      response(400, "bad request") { schema ::Shared::V1::Schemas::ValidationError }
      response(401, "unauthorized") { schema ::Shared::V1::Schemas::StandardError }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  api_path "/friends/{username}/accept" do
    parameter name: "username", in: :path, schema: {type: :string}, description: "The other user's username"

    put("Accept Friend Request") do
      operationId "acceptFriendship"
      tags "Friends"
      produces "application/json"

      security WRITE_SECURITY

      response(200, "successful") { schema ::V1::Schemas::Friendship }
      response(401, "unauthorized") { schema ::Shared::V1::Schemas::StandardError }
      response(403, "forbidden") { schema ::Shared::V1::Schemas::StandardError }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  api_path "/friends/{username}/decline" do
    parameter name: "username", in: :path, schema: {type: :string}, description: "The other user's username"

    put("Decline Friend Request") do
      operationId "declineFriendship"
      tags "Friends"
      produces "application/json"

      security WRITE_SECURITY

      response(200, "successful") { schema ::V1::Schemas::Friendship }
      response(401, "unauthorized") { schema ::Shared::V1::Schemas::StandardError }
      response(403, "forbidden") { schema ::Shared::V1::Schemas::StandardError }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  api_path "/friends/{username}/ignore" do
    parameter name: "username", in: :path, schema: {type: :string}, description: "The other user's username"

    put("Ignore Friend Request") do
      operationId "ignoreFriendship"
      tags "Friends"
      produces "application/json"

      security WRITE_SECURITY

      response(200, "successful") { schema ::V1::Schemas::Friendship }
      response(401, "unauthorized") { schema ::Shared::V1::Schemas::StandardError }
      response(403, "forbidden") { schema ::Shared::V1::Schemas::StandardError }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  setup do
    Flipper.enable("friends")

    @user = create(:user)
    @other = create(:user)
  end

  def request_from_other
    create(:friendship, requester: @other, addressee: @user)
  end

  test "PUT accept makes them friends" do
    request_from_other
    sign_in @user

    assert_api_response :put, 200, api_path: ACCEPT_PATH, path_params: {username: @other.username} do
      assert_equal "accepted", parsed_body["state"]
    end

    assert @user.reload.friend_of?(@other)
  end

  test "PUT decline turns it away" do
    friendship = request_from_other
    sign_in @user

    assert_api_response :put, 200, api_path: DECLINE_PATH, path_params: {username: @other.username} do
      assert_equal "declined", parsed_body["state"]
    end

    assert friendship.reload.declined?
  end

  test "PUT ignore hides it, and the sender sees no change at all" do
    friendship = request_from_other
    sign_in @user

    assert_api_response :put, 200, api_path: IGNORE_PATH, path_params: {username: @other.username} do
      assert_equal "ignored", parsed_body["state"]
    end

    assert friendship.reload.ignored?

    sign_out @user
    sign_in @other

    assert_api_response :get, 200, path_params: {username: @user.username} do
      assert_equal "pending", parsed_body["state"]
    end
  end

  # The requirement stated as a payload comparison: whatever the recipient did,
  # the sender's view of the row is the same bytes.
  test "an ignored request renders to the sender exactly as a pending one" do
    create(:friendship, requester: @other, addressee: @user)
    untouched_target = create(:user)
    create(:friendship, requester: @other, addressee: untouched_target)

    sign_in @user
    put "/api/v1/friends/#{@user.friendship_with(@other).other_party_for(@other).username}/ignore"
    sign_out @user

    sign_in @other
    assert_api_response :get, 200, path_params: {username: @user.username}
    ignored_view = parsed_body

    assert_api_response :get, 200, path_params: {username: untouched_target.username}
    pending_view = parsed_body

    # Everything except the row's own identity and its clock.
    varies = %w[id user createdAt updatedAt]

    assert_equal pending_view.except(*varies), ignored_view.except(*varies)
  end

  # 403 rather than 404: the sender already knows this row exists, they made it.
  # And it is the same 403 they would get for a request that had been accepted
  # or declined, so it tells them nothing about which.
  test "the sender cannot answer their own request" do
    create(:friendship, requester: @user, addressee: @other)
    sign_in @user

    assert_api_response :put, 403, api_path: ACCEPT_PATH, path_params: {username: @other.username}
  end

  test "answering is refused the same way whatever the recipient did" do
    create(:friendship, :ignored, requester: @user, addressee: @other)
    declined_target = create(:user)
    create(:friendship, :declined, requester: @user, addressee: declined_target)
    sign_in @user

    assert_api_response :put, 403, api_path: ACCEPT_PATH, path_params: {username: @other.username}
    ignored_refusal = parsed_body

    assert_api_response :put, 403, api_path: ACCEPT_PATH, path_params: {username: declined_target.username}

    assert_equal parsed_body, ignored_refusal
  end

  test "answering something that does not exist is a 404" do
    sign_in @user

    assert_api_response :put, 404, api_path: ACCEPT_PATH, path_params: {username: @other.username}
  end

  test "DELETE withdraws a request the user sent" do
    create(:friendship, requester: @user, addressee: @other)
    sign_in @user

    assert_api_response :delete, 204, path_params: {username: @other.username}
    assert_nil Friendship.between(@user, @other)
  end

  test "DELETE ends an accepted friendship from either side" do
    create(:friendship, :accepted, requester: @other, addressee: @user)
    sign_in @user

    assert_api_response :delete, 204, path_params: {username: @other.username}
    assert_nil Friendship.between(@user, @other)
  end

  # Withdrawing has to answer the same either way, and must not clear the
  # ignore -- otherwise withdraw-and-ask-again walks straight back in.
  test "DELETE on a request that was ignored answers the same and changes nothing" do
    ignored = create(:friendship, :ignored, requester: @user, addressee: @other)
    sign_in @user

    assert_api_response :delete, 204, path_params: {username: @other.username}
    assert ignored.reload.ignored?
  end

  # Withdrawing is only invisible if what follows it is too: the row must be
  # gone from the sender's list and 404 on a direct read, exactly as a real
  # withdrawal leaves things.
  test "a withdrawn request is gone from the sender's view, ignored or not" do
    create(:friendship, :ignored, requester: @user, addressee: @other)
    plain_target = create(:user)
    create(:friendship, requester: @user, addressee: plain_target)
    sign_in @user

    [@other, plain_target].each do |target|
      assert_api_response :delete, 204, path_params: {username: target.username}
      assert_api_response :get, 404, path_params: {username: target.username}
    end

    get "/api/v1/friends?state=pending&direction=outgoing"

    assert_empty parsed_body["items"]
  end

  test "asking again after withdrawing answers the same either way" do
    create(:friendship, :ignored, requester: @user, addressee: @other)
    plain_target = create(:user)
    create(:friendship, requester: @user, addressee: plain_target)
    sign_in @user

    answers = [@other, plain_target].map do |target|
      delete "/api/v1/friends/#{target.username}"
      post "/api/v1/friends", params: {username: target.username}, as: :json

      [response.status, parsed_body.except("id", "user", "createdAt", "updatedAt")]
    end

    assert_equal answers.first, answers.last
  end

  test "GET without a session is unauthorized" do
    create(:friendship, :accepted, requester: @user, addressee: @other)

    assert_api_response :get, 401, path_params: {username: @other.username}
  end

  test "GET a relationship that does not exist is a 404" do
    sign_in @user

    assert_api_response :get, 404, path_params: {username: @other.username}
  end
end
