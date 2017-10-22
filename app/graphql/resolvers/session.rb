# encoding: utf-8
# frozen_string_literal: true

module Resolvers
  class Session < Resolvers::Base
    def resolve
      if current_user.blank?
        login
      else
        logout
      end
    end

    def login
      user = User.find_for_database_authentication(login: args[:login])

      result = {}

      authorize(user)

      if errors.blank?
        result[:token] = JsonWebToken.encode(new_auth_token(user.id).to_jwt_payload)
      end

      OpenStruct.new(result)
    end

    def logout
      auth_token = AuthToken.find_by(user_id: current_user.id, token: jwt_token[:token])

      OpenStruct.new(
        success: auth_token && auth_token.destroy,
        code: 'session.destroy',
        message: I18n.t("devise.sessions.signed_out")
      )
    end

    private def authorize(user)
      if user.blank?
        errors << { code: 'session.not_found_in_database', message: I18n.t('devise.failure.not_found_in_database') }
      else
        unless user.confirmed?
          errors << { code: 'session.unconfirmed', message: I18n.t('devise.failure.unconfirmed') }
        end

        unless user.valid_password?(args[:password])
          errors << { code: 'session.invalid', message: I18n.t('devise.failure.not_found_in_database') }
        end
      end
    end

    private def new_auth_token(user_id)
      @new_auth_token = AuthToken.create(
        user_id: user_id,
        user_agent: ctx[:user_agent],
        description: args[:description],
        expires: args[:expires]
      )
    end
  end
end
