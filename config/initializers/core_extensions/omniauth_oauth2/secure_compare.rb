# frozen_string_literal: true

require "omniauth-oauth2"

# omniauth-oauth2 compares the callback's state against one it deletes from the
# session, and raises unless both are strings: a nil from a reloaded callback or
# a lost cookie, an array from `state[]=`. The NoMethodError then fails the
# callback as an unexpected error rather than as csrf_detected.
#
# csrf_detected is not reported, so a missing session state is logged instead.
# It is what a session cookie regression looks like: every sign-in failing with
# nothing in the error tracker.
module CoreExtensions
  module OmniauthOAuth2
    module SecureCompare
      protected def secure_compare(string_a, string_b)
        Rails.logger.warn("OAuth callback without a session state, strategy: #{name}") if string_b.nil?

        return false unless string_a.is_a?(String) && string_b.is_a?(String)

        super
      end
    end
  end
end

OmniAuth::Strategies::OAuth2.prepend(CoreExtensions::OmniauthOAuth2::SecureCompare)
