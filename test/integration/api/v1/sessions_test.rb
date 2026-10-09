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

  test "POST /sessions signs in a browser still holding a timed out session" do
    user = create(:user, password: "enterprise")
    browser = open_session
    sign_in_json(browser, user, remember: false)
    hold_session_cookie(browser)

    travel(Devise.timeout_in + 1.minute) do
      sign_in_json(browser, user, remember: false)

      browser.get "/api/v1/users/me"
      assert_equal 200, browser.response.status
    end
  end

  test "POST /sessions with a wrong password leaves a timed out session timed out" do
    user = create(:user, password: "enterprise")
    browser = open_session
    sign_in_json(browser, user, remember: false)
    hold_session_cookie(browser)

    travel(Devise.timeout_in + 1.minute) do
      browser.post "/api/v1/sessions",
        params: {login: user.username, password: "wrong-password"}.to_json,
        headers: {"CONTENT_TYPE" => "application/json"}
      assert_equal 400, browser.response.status

      browser.get "/api/v1/users/me"
      assert_equal 401, browser.response.status
    end
  end

  test "POST /sessions remembers a browser signing back in after a time out" do
    user = create(:user, password: "enterprise")
    browser = open_session
    sign_in_json(browser, user, remember: false)
    hold_session_cookie(browser)

    travel(Devise.timeout_in + 1.minute) do
      sign_in_json(browser, user, remember: true)

      assert_predicate remember_cookie(browser), :present?
    end
  end

  test "POST /sessions with a wrong password leaves a signed in session alone" do
    user = create(:user, password: "enterprise")
    browser = open_session
    sign_in_json(browser, user, remember: false)

    browser.post "/api/v1/sessions",
      params: {login: user.username, password: "wrong-password"}.to_json,
      headers: {"CONTENT_TYPE" => "application/json"}
    assert_equal 400, browser.response.status

    browser.get "/api/v1/users/me"
    assert_equal 200, browser.response.status
  end

  test "POST /sessions signs in another account over a remembered one" do
    remembered = create(:user, password: "enterprise")
    other = create(:user, password: "enterprise")
    browser = sign_in_remembered(remembered)
    browser.cookies.delete(SESSION_COOKIE)

    sign_in_json(browser, other, remember: false)
    browser.cookies.delete(REMEMBER_COOKIE)
    browser.get "/api/v1/users/me"

    assert_equal other.id, JSON.parse(browser.response.body)["id"]
    assert_nil remembered.reload.last_active_at
  end

  test "POST /sessions signs in with a second factor after asking for it" do
    user = create(:user, password: "enterprise", otp_secret: User.generate_otp_secret, otp_required_for_login: true)
    browser = open_session

    browser.post "/api/v1/sessions",
      params: {login: user.username, password: "enterprise"}.to_json,
      headers: {"CONTENT_TYPE" => "application/json"}
    assert_equal "session.create.two_factor_required", JSON.parse(browser.response.body)["code"]

    browser.post "/api/v1/sessions",
      params: {login: user.username, password: "enterprise", twoFactorCode: user.current_otp}.to_json,
      headers: {"CONTENT_TYPE" => "application/json"}
    assert_equal 200, browser.response.status

    browser.get "/api/v1/users/me"
    assert_equal 200, browser.response.status
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

  test "DELETE /sessions ends the session for the next request" do
    user = create(:user, password: "enterprise")
    browser = open_session
    sign_in_json(browser, user, remember: false)

    browser.delete "/api/v1/sessions"
    browser.get "/api/v1/users/me"

    assert_equal 401, browser.response.status
  end

  test "DELETE /sessions ends a timed out session" do
    user = create(:user, password: "enterprise")
    browser = open_session
    sign_in_json(browser, user, remember: false)
    hold_session_cookie(browser)

    travel(Devise.timeout_in + 1.minute) do
      browser.delete "/api/v1/sessions"
      assert_equal 200, browser.response.status
    end

    browser.get "/api/v1/users/me"
    assert_equal 401, browser.response.status
  end

  test "DELETE /sessions returns 401 when not signed in" do
    assert_api_response :delete, 401
  end

  # ==> remember me
  SESSION_COOKIE = Rails.configuration.cookie_prefix
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

  # A request sent before signing in can answer after it, and the browser keeps
  # whichever session cookie arrives last.
  test "a request still in flight from before signing in leaves the new session alone" do
    assert_signed_in_after_late_answer_from "/api/v1/users/me", previous_session: unknown_session
  end

  test "a public request still in flight from before signing in leaves the new session alone" do
    assert_signed_in_after_late_answer_from "/api/v1/manufacturers", previous_session: unknown_session
  end

  test "a request still in flight from a timed out session leaves the new session alone" do
    user = create(:user, password: "enterprise")
    previous = open_session
    sign_in_json(previous, user, remember: false)
    previous_session = "#{SESSION_COOKIE}=#{previous.cookies[SESSION_COOKIE]}; domain=example.com; path=/"

    travel(Devise.timeout_in + 1.minute) do
      assert_signed_in_after_late_answer_from "/api/v1/users/me", previous_session:, user:
    end
  end

  test "a remembered browser of a deactivated account gets no session cookie" do
    user = create(:user, password: "enterprise")
    browser = sign_in_remembered(user)
    user.update_columns(confirmed_at: nil, confirmation_sent_at: 1.week.ago)
    browser.cookies.delete(SESSION_COOKIE)

    browser.get "/api/v1/users/me"

    assert_equal 401, browser.response.status
    assert_nil session_cookie(browser)
  end

  test "a remembered sign in is kept when the request that made it fails" do
    browser = sign_in_remembered(create(:user, password: "enterprise"))
    browser.cookies.delete(SESSION_COOKIE)

    browser.delete "/api/v1/vehicles/#{SecureRandom.uuid}"
    assert_equal 404, browser.response.status

    browser.cookies.delete(REMEMBER_COOKIE)
    browser.get "/api/v1/users/me"

    assert_equal 200, browser.response.status
  end

  private def assert_signed_in_after_late_answer_from(path, previous_session:, user: create(:user, password: "enterprise"))
    browser = open_session
    browser.cookies.merge(previous_session, browser_uri)
    in_flight = open_session
    in_flight.cookies.merge(previous_session, browser_uri)

    sign_in_json(browser, user, remember: false)

    in_flight.get path
    Array(in_flight.response.headers["Set-Cookie"]).each do |cookie|
      browser.cookies.merge(cookie, browser_uri)
    end

    browser.get "/api/v1/users/me"

    assert_equal 200, browser.response.status
  end

  # The cookie expires with the session's `expire_after`, which the test jar
  # honours across `travel`. A browser whose cookie was refreshed by a request
  # that never asked for the user still holds it when the user has timed out.
  private def hold_session_cookie(browser)
    browser.cookies.merge("#{SESSION_COOKIE}=#{browser.cookies[SESSION_COOKIE]}; domain=example.com; path=/", browser_uri)
  end

  private def session_cookie(browser)
    Array(browser.response.headers["Set-Cookie"]).find { |cookie| cookie.start_with?("#{SESSION_COOKIE}=") }
  end

  private def unknown_session
    "#{SESSION_COOKIE}=#{SecureRandom.hex(16)}; domain=example.com; path=/"
  end

  private def browser_uri
    URI("http://www.example.com/")
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
