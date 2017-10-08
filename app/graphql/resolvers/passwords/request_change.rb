# encoding: utf-8
# frozen_string_literal: true

module Resolvers
  module Passwords
    class RequestChange < Resolvers::Base
      def resolve
        user = User.find_by!(email: args[:email])
        user.send_reset_password_instructions

        OpenStruct.new(
          success: true,
          code: 'request_pasword.success',
          message: I18n.t('devise.passwords.send_paranoid_instructions')
        )
      end
    end
  end
end
