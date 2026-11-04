# frozen_string_literal: true

require "test_helper"

class OmniauthOAuth2SecureCompareTest < ActiveSupport::TestCase
  test "a callback whose session holds no state fails as csrf_detected and is logged" do
    Rails.logger.expects(:warn).with(includes("without a session state")).once

    assert_equal :csrf_detected, failure_type_for("state=abc", session: {})
  end

  test "a callback with an array for its state fails as csrf_detected" do
    assert_equal :csrf_detected, failure_type_for("state[]=abc", session: {"omniauth.state" => "abc"})
  end

  test "a callback whose state does not match fails as csrf_detected without a log line" do
    Rails.logger.expects(:warn).never

    assert_equal :csrf_detected, failure_type_for("state=abc", session: {"omniauth.state" => "xyz"})
  end

  test "the comparison stays out of the strategy's public interface" do
    assert_not strategy.respond_to?(:secure_compare)
  end

  private def failure_type_for(query, session:)
    subject = strategy
    subject.instance_variable_set(
      :@env,
      Rack::MockRequest.env_for("/users/auth/oauth2/callback?#{query}", "rack.session" => session)
    )

    failure = nil
    subject.define_singleton_method(:fail!) { |type, _exception = nil| failure = type }
    subject.callback_phase
    failure
  end

  private def strategy
    OmniAuth::Strategies::OAuth2.new(->(_env) { [200, {}, []] }, "id", "secret")
  end
end
