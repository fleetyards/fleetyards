# frozen_string_literal: true

require 'json_web_token'
require 'useragent'

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
        return fail! if claims.key?(:token) && !AuthToken.exists?(token: claims[:token], key: key)

        success!(User.find(claims[:user_id]))
      end

      protected def key
        user_agent = UserAgent.parse(request.user_agent)
        Digest::SHA512.hexdigest("#{user_agent.browser}-#{user_agent.platform}")
      end

      protected def auth_params
        auth_params, _options = token_and_options(request)
        auth_params
      end
    end
  end
end
