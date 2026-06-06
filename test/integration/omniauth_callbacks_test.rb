# frozen_string_literal: true

require "test_helper"

class OmniauthCallbacksTest < ActionDispatch::IntegrationTest
  EMAIL = "oauth@example.com"
  UID = "123456"
  NICKNAME = "oauthuser"

  %i[discord twitch google github].each do |provider|
    test "##{provider} creates a new user and signs in when not signed in and no existing user or connection" do
      mock_omniauth(provider, uid: UID, email: EMAIL, nickname: NICKNAME)

      assert_difference -> { User.count } => 1, -> { OmniauthConnection.count } => 1 do
        post "/users/auth/#{provider}/callback"
      end

      assert_response :redirect
    end

    test "##{provider} creates an omniauth connection with correct attributes" do
      mock_omniauth(provider, uid: UID, email: EMAIL, nickname: NICKNAME)

      post "/users/auth/#{provider}/callback"

      connection = OmniauthConnection.last
      assert_equal UID, connection.uid
      assert_equal provider.to_s, connection.provider
      assert_equal User.last, connection.user
      assert connection.auth_payload.present?
    end

    test "##{provider} sets the username from oauth nickname" do
      mock_omniauth(provider, uid: UID, email: EMAIL, nickname: NICKNAME)

      post "/users/auth/#{provider}/callback"

      assert_equal NICKNAME, User.last.username
    end

    test "##{provider} signs in the existing user with matching email and creates a connection" do
      mock_omniauth(provider, uid: UID, email: EMAIL, nickname: NICKNAME)
      existing_user = create(:user, email: EMAIL)

      assert_difference -> { OmniauthConnection.count }, 1 do
        post "/users/auth/#{provider}/callback"
      end

      assert_equal 1, User.count
      assert_equal existing_user, OmniauthConnection.last.user
    end

    test "##{provider} signs in the connected user without creating a new connection" do
      mock_omniauth(provider, uid: UID, email: EMAIL, nickname: NICKNAME)
      existing_user = create(:user)
      create(:omniauth_connection, user: existing_user, uid: UID, provider: provider)

      assert_no_difference -> { OmniauthConnection.count } do
        post "/users/auth/#{provider}/callback"
      end

      assert_response :redirect
    end

    test "##{provider} redirects with failure message when username is already taken" do
      mock_omniauth(provider, uid: UID, email: EMAIL, nickname: NICKNAME)
      create(:user, username: NICKNAME)

      post "/users/auth/#{provider}/callback"

      assert_response :redirect
      assert flash[:alert].present?
    end

    test "##{provider} creates a connection to the current user when signed in" do
      mock_omniauth(provider, uid: UID, email: EMAIL, nickname: NICKNAME)
      user = create(:user)
      sign_in user

      assert_difference -> { user.omniauth_connections.count }, 1 do
        post "/users/auth/#{provider}/callback"
      end

      connection = OmniauthConnection.last
      assert_equal user, connection.user
      assert_equal UID, connection.uid
      assert_equal provider.to_s, connection.provider
      assert_response :redirect
    end

    test "##{provider} redirects with already connected notice when provider already connected" do
      mock_omniauth(provider, uid: UID, email: EMAIL, nickname: NICKNAME)
      user = create(:user)
      sign_in user
      create(:omniauth_connection, user: user, uid: UID, provider: provider)

      assert_no_difference -> { OmniauthConnection.count } do
        post "/users/auth/#{provider}/callback"
      end

      assert_response :redirect
      assert_includes flash[:notice], "already"
    end
  end

  test "#failure redirects with an alert on authentication failure" do
    OmniAuth.config.mock_auth[:discord] = :invalid_credentials

    get "/users/auth/discord/callback"

    assert_response :redirect
  end
end
