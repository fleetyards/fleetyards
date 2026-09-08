# frozen_string_literal: true

require "openapi_helper"

class Api::V1::SessionsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/sessions" do
    post("create session") do
      operationId "createSession"
      tags "Sessions"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::SessionInput

      response(200, "successful") do
        schema ::V1::Schemas::User
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end

    delete("Destroy Session") do
      operationId "destroySession"
      tags "Sessions"
      produces "application/json"

      security [{
        SessionCookie: []
      }]

      response(200, "successful") do
        schema ::V1::Schemas::StandardMessage
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  # POST /sessions
  test "POST /sessions signs the user in" do
    user = create(:user, password: "enterprise")

    assert_api_response :post, 200, body: {login: user.username, password: "enterprise"}
  end

  test "POST /sessions returns 400 for missing body" do
    assert_api_response :post, 400, body: nil
  end

  # DELETE /sessions
  test "DELETE /sessions signs the user out" do
    user = create(:user)
    sign_in user

    assert_api_response :delete, 200
  end

  test "DELETE /sessions returns 401 when not signed in" do
    assert_api_response :delete, 401
  end

  # ==> remember me
  REMEMBER_COOKIE = "#{Rails.configuration.cookie_prefix}_USER_STORED_#{Rails.env.upcase}"

  test "a remembered browser stays signed in once its session is gone" do
    browser = sign_in_remembered(create(:user, password: "enterprise"))

    browser.cookies.delete(Rails.configuration.cookie_prefix)
    browser.get "/api/v1/users/me"

    assert_equal 200, browser.response.status
  end

  test "DELETE /sessions leaves other remembered browsers signed in" do
    user = create(:user, password: "enterprise")
    browser = sign_in_remembered(user)

    elsewhere = open_session
    sign_in_json(elsewhere, user, remember: false)
    elsewhere.delete "/api/v1/sessions"
    assert_equal 200, elsewhere.response.status

    browser.cookies.delete(Rails.configuration.cookie_prefix)
    browser.get "/api/v1/users/me"

    assert_equal 200, browser.response.status
  end

  test "signing in on one device does not unremember the other" do
    user = create(:user, password: "enterprise")
    phone = sign_in_remembered(user)

    # the axios interceptor signs out on any 401, then the user logs back in
    computer = sign_in_remembered(user)
    computer.delete "/api/v1/sessions"
    sign_in_json(computer, user, remember: true)

    phone.cookies.delete(Rails.configuration.cookie_prefix)
    phone.get "/api/v1/users/me"

    assert_equal 200, phone.response.status
  end

  test "DELETE /sessions drops the remember cookie of the browser doing it" do
    browser = sign_in_remembered(create(:user, password: "enterprise"))

    browser.delete "/api/v1/sessions"

    assert_predicate remember_cookie(browser).to_s, :empty?
  end

  test "a remembered browser does not count as another sign in" do
    user = create(:user, password: "enterprise")
    browser = sign_in_remembered(user)
    signed_in = user.reload.slice(:sign_in_count, :current_sign_in_at)

    browser.cookies.delete(Rails.configuration.cookie_prefix)
    browser.get "/api/v1/users/me"

    assert_equal 200, browser.response.status
    assert_equal signed_in, user.reload.slice(:sign_in_count, :current_sign_in_at)
  end

  test "signing in with a password still counts" do
    user = create(:user, password: "enterprise")
    browser = open_session

    assert_difference -> { user.reload.sign_in_count }, 1 do
      sign_in_json(browser, user, remember: true)
    end
  end

  private def sign_in_remembered(user)
    browser = open_session
    sign_in_json(browser, user, remember: true)

    value = remember_cookie(browser)
    assert value.present?, "expected a remember-me cookie"
    browser.cookies[REMEMBER_COOKIE] = value

    browser
  end

  private def sign_in_json(browser, user, remember:)
    browser.post "/api/v1/sessions",
      params: {login: user.username, password: "enterprise", rememberMe: remember}.to_json,
      headers: {"CONTENT_TYPE" => "application/json"}

    assert_equal 200, browser.response.status
  end

  # The remember cookie is scoped to the app's configured domain, which is not the
  # host integration tests run on, so the test jar throws it away. Read it off the
  # response instead, and put it back by hand where a real browser would have kept it.
  private def remember_cookie(browser)
    Array(browser.response.headers["Set-Cookie"])
      .find { |cookie| cookie.start_with?(REMEMBER_COOKIE) }
      &.then { |cookie| CGI.unescape(cookie[/#{REMEMBER_COOKIE}=([^;]*)/o, 1].to_s) }
  end
end
