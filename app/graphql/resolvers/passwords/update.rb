# encoding: utf-8
# frozen_string_literal: true

module Resolvers
  module Passwords
    class Update < Resolvers::Base
      def resolve
        if current_user.present?
          update
        else
          update_with_token
        end
      end

      private def update_with_token
        user = User.reset_password_by_token(args[:data].to_h.symbolize_keys)
        if user.errors.blank?
          success
        else
          add_active_record_errors(user)
          failure
        end
      end

      private def update
        user = current_user
        if user.update_with_password(args[:data].to_h.symbolize_keys)
          success
        else
          add_active_record_errors(user)
          failure
        end
      end

      private def success
        OpenStruct.new(
          success: true,
          code: 'change_pasword.success',
          message: I18n.t('devise.passwords.updated_not_active')
        )
      end

      private def failure
        OpenStruct.new(
          success: false,
          code: 'change_pasword.failure',
          message: I18n.t('devise.passwords.update_failure')
        )
      end
    end
  end
end
