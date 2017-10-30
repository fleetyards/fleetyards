# frozen_string_literal: true

require 'json_web_token'

module Devise
  module Strategies
    class JWT < Base
      include ActionController::HttpAuthentication::Token

      def valid?
        auth_params.present?
      end

      def authenticate!
        claims = ::JsonWebToken.decode(auth_params)
        return fail! unless claims
        return fail! unless claims.key?(:user_id)
        return fail! if claims.key?(:token) && !AuthToken.exists?(token: claims[:token])

        success!(User.find(claims[:user_id]))
      end

      protected def auth_params
        auth_params, _options = token_and_options(request)
        auth_params
      end
    end
  end
end
