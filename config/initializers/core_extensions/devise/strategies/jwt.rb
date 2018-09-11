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
        return fail! unless claims.key?(:user)
        return fail! unless AuthToken.exists?(user_id: claims[:user], user_agent: "#{user_agent.browser}-#{user_agent.platform}")

        success!(User.find(claims[:user]))
      end

      protected def user_agent
        UserAgent.parse(request.user_agent)
      end

      protected def auth_params
        auth_params, _options = token_and_options(request)
        auth_params
      end
    end
  end
end
