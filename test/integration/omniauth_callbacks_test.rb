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

  # The avatar is the provider's pick, not the user's, so one the app refuses
  # to store must not cost them the sign-in. Nothing is fetched either: the URL
  # here points nowhere, and reaching it would fail the test.
  test "an avatar the app will not store is passed over rather than failing the sign in" do
    mock_omniauth(:google, uid: UID, email: EMAIL, nickname: NICKNAME, image: "https://example.com/avatar.svg")

    assert_difference -> { User.count }, 1 do
      post "/users/auth/google/callback"
    end

    assert_response :redirect
    assert_not_predicate User.last.avatar, :attached?
  end

  ["/login/", "/login", "/login/?foo=bar", "/sign-up/"].each do |path|
    test "a sign in started from #{path} lands on the hangar" do
      mock_omniauth(:google, uid: UID, email: EMAIL, nickname: NICKNAME)

      get "/users/auth/google/callback", env: {"omniauth.origin" => "http://#{Rails.configuration.app.domain}#{path}"}

      assert_redirected_to frontend_hangar_url
    end
  end

  test "a sign in started from another page goes back to it" do
    mock_omniauth(:google, uid: UID, email: EMAIL, nickname: NICKNAME)
    origin = "http://#{Rails.configuration.app.domain}/settings/"

    get "/users/auth/google/callback", env: {"omniauth.origin" => origin}

    assert_redirected_to origin
  end

  test "a sign in with an origin that is not a URL lands on the hangar" do
    mock_omniauth(:google, uid: UID, email: EMAIL, nickname: NICKNAME)

    get "/users/auth/google/callback", env: {"omniauth.origin" => "http://exa mple.com/login"}

    assert_redirected_to frontend_hangar_url
  end

  test "a sign in with an origin on another host lands on the hangar" do
    mock_omniauth(:google, uid: UID, email: EMAIL, nickname: NICKNAME)

    get "/users/auth/google/callback", env: {"omniauth.origin" => "https://evil.example/settings/"}

    assert_redirected_to frontend_hangar_url
  end

  test "a sign in with a non-web origin on the frontend host lands on the hangar" do
    mock_omniauth(:google, uid: UID, email: EMAIL, nickname: NICKNAME)
    host = URI.parse(frontend_root_url).host

    get "/users/auth/google/callback", env: {"omniauth.origin" => "javascript://#{host}/%0aalert(1)"}

    assert_redirected_to frontend_hangar_url
  end

  test "a sign in started on the frontend host in other casing goes back to it" do
    mock_omniauth(:google, uid: UID, email: EMAIL, nickname: NICKNAME)
    origin = "http://#{URI.parse(frontend_root_url).host.upcase}/settings/"

    get "/users/auth/google/callback", env: {"omniauth.origin" => origin}

    assert_redirected_to origin
  end

  test "a sign in with a taken username goes back to the page it started on" do
    mock_omniauth(:google, uid: UID, email: EMAIL, nickname: NICKNAME)
    create(:user, username: NICKNAME)
    origin = "http://#{Rails.configuration.app.domain}/sign-up/"

    get "/users/auth/google/callback", env: {"omniauth.origin" => origin}

    assert_redirected_to origin
  end

  test "a sign in with a taken username and an origin on another host goes to the login page" do
    mock_omniauth(:google, uid: UID, email: EMAIL, nickname: NICKNAME)
    create(:user, username: NICKNAME)

    get "/users/auth/google/callback", env: {"omniauth.origin" => "https://evil.example/login"}

    assert_redirected_to frontend_login_url
  end

  test "#failure redirects with an alert on authentication failure" do
    OmniAuth.config.mock_auth[:discord] = :invalid_credentials

    get "/users/auth/discord/callback"

    assert_response :redirect
  end

  test "#citizenid verifies the handle it names and takes it from the account that held it" do
    holder = create(:user)
    holder.verify_rsi_handle("TestPilot", via: :rsi_profile)
    holder.save!
    mock_omniauth(:citizenid, uid: UID, email: EMAIL, nickname: NICKNAME)
    OmniAuth.config.mock_auth[:citizenid].extra = {raw_info: {"urn:user:rsi:username" => "TestPilot"}}

    post "/users/auth/citizenid/callback"

    assert_response :redirect
    user = User.find_by!(normalized_email: EMAIL)
    assert user.rsi_handle_verified_via_citizenid?
    assert_equal "TestPilot", user.rsi_handle
    assert_not holder.reload.rsi_handle_verified?
  end

  test "#citizenid stores the orgs its claim lists and verifies the memberships in them" do
    user = create(:user, email: EMAIL)
    fleet = create(:fleet, rsi_sid: "MAIN", members: [user])
    other = create(:fleet, rsi_sid: "OTHER", members: [user])
    mock_omniauth(:citizenid, uid: UID, email: EMAIL, nickname: NICKNAME)
    OmniAuth.config.mock_auth[:citizenid].extra = {raw_info: {"urn:user:rsi:username" => "TestPilot", "urn:user:rsi:orgs:public" => ["main"]}}

    post "/users/auth/citizenid/callback"

    assert_equal %w[MAIN], user.reload.rsi_organization_sids
    assert fleet.fleet_memberships.find_by(user:).verified?
    assert_not other.fleet_memberships.find_by(user:).verified?
  end
end
