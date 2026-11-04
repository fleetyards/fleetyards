# frozen_string_literal: true

require "omniauth-oauth2"

# omniauth-oauth2 1.9.0 compares the callback's state against one it deletes
# from the session, which is nil on a reloaded callback or a lost cookie. The
# comparison then raises instead of returning false, so the callback fails with
# the NoMethodError's text as its reason, shown to the user, rather than as
# csrf_detected.
#
# A newer release may handle this itself, so it has to be checked against this
# before the patch is kept.
unless OmniAuth::OAuth2::VERSION == "1.9.0"
  raise "omniauth-oauth2 #{OmniAuth::OAuth2::VERSION} is not the version #{__FILE__} guards secure_compare for"
end

module CoreExtensions
  module OmniauthOAuth2
    module SecureCompare
      def secure_compare(string_a, string_b)
        return false if string_a.nil? || string_b.nil?

        super
      end
    end
  end
end

OmniAuth::Strategies::OAuth2.prepend(CoreExtensions::OmniauthOAuth2::SecureCompare)
