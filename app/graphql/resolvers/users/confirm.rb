# encoding: utf-8
# frozen_string_literal: true

module Resolvers
  module Users
    class Confirm < Resolvers::Base
      def resolve
        user = User.confirm_by_token(args[:token])

        add_active_record_errors(user)

        if errors.blank?
          OpenStruct.new(
            success: true,
            code: 'confirmation.success',
            message: I18n.t('devise.confirmations.confirmed')
          )
        else
          OpenStruct.new(
            success: false,
            code: 'confirmation.failure',
            message: I18n.t('devise.failure.not_confirmed')
          )
        end
      end
    end
  end
end
