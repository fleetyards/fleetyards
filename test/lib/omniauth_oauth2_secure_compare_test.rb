# frozen_string_literal: true

require "test_helper"

class OmniauthOAuth2SecureCompareTest < ActiveSupport::TestCase
  test "a callback whose session holds no state fails as csrf_detected" do
    assert_equal :csrf_detected, failure_type_for(session: {})
  end

  test "a callback whose state does not match fails as csrf_detected" do
    assert_equal :csrf_detected, failure_type_for(session: {"omniauth.state" => "other"})
  end

  private def failure_type_for(session:)
    strategy = OmniAuth::Strategies::OAuth2.new(->(_env) { [200, {}, []] }, "id", "secret")
    strategy.instance_variable_set(
      :@env,
      Rack::MockRequest.env_for("/users/auth/oauth2/callback?state=abc", "rack.session" => session)
    )

    failure = nil
    strategy.define_singleton_method(:fail!) { |type, _exception = nil| failure = type }
    strategy.callback_phase
    failure
  end
end
