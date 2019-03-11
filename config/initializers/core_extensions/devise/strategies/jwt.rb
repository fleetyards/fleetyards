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
        claim = ::JsonWebToken.decode(auth_params)
        return fail! unless claim
        return fail! unless claim.key?(:user)
        return fail! unless auth_token?(claim)

        success!(User.find_by(id: claim[:user]))
      end

      protected def auth_token?(claim)
        AuthToken.exists?(user_id: claim[:user], client_key: claim[:client_key])
      end

      protected def auth_params
        auth_params, _options = token_and_options(request)
        auth_params
      end
    end
  end
end
