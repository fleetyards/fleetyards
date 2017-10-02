# encoding: utf-8
# frozen_string_literal: true

module Resolvers
  class Sessions < Resolvers::Base
    def resolve
      user = ::User.find_for_database_authentication(login: args[:login])

      result = {
        token: nil,
        errors: authorize(user)
      }

      if result[:errors].blank?
        result[:token] = ::JsonWebToken.encode(new_auth_token(user.id).to_jwt_payload)
      end

      OpenStruct.new(result)
    end

    private def authorize(user)
      errors = []

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

      errors
    end

    private def new_auth_token(user_id)
      @new_auth_token ||= begin
        AuthToken.create(
          user_id: user_id,
          user_agent: ctx[:user_agent],
          description: args[:description],
          expires: args[:expires]
        )
      end
    end
  end
end
