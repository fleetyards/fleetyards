# frozen_string_literal: true

require "useragent"

module Devise
  module Strategies
    class ApiToken < Base
      include ActionController::HttpAuthentication::Token

      def valid?
        auth_token.present?
      end

      def authenticate!
        token = AuthToken.find_by(token: auth_token)

        return fail! if token.blank?
        return fail! if token.expired?

        success!(token.user)
      end

      protected def auth_token
        auth_token, _options = token_and_options(request)
        auth_token
      end
    end
  end
end
