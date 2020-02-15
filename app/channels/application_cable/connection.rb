# frozen_string_literal: true

require 'json_web_token'

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private def find_verified_user
      claim = ::JsonWebToken.decode(request.params[:token])

      return unless claim
      return unless claim.key?(:user)
      return unless auth_token?(claim)

      ::User.find_by(id: claim[:user])
    end

    private def auth_token?(claim)
      ::AuthToken.exists?(user_id: claim[:user], client_key: claim[:client_key])
    end
  end
end
