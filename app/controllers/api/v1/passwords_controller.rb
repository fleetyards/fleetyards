# encoding: utf-8
# frozen_string_literal: true

module Api
  module V1
    class PasswordsController < ActionController::Base
      skip_authorization_check
      before_action :authenticate_api_user!, only: []

      def request_email
        user = User.find_by(email: params[:email])
        if user.present?
          user.send_reset_password_instructions
          render json: { code: 'request_pasword.success', message: I18n.t('devise.passwords.send_paranoid_instructions') }
        else
          render json: ValidationError.new("request_password"), status: :bad_request
        end
      end

      def update
        user = User.reset_password_by_token(change_password_params)
        if user.errors.blank?
          render json: { code: 'change_pasword.success', message: I18n.t('devise.passwords.updated_not_active') }
        else
          render json: ValidationError.new("change_pasword", user.errors), status: :bad_request
        end
      end

      private def change_password_params
        @change_password_params ||= params.permit(:reset_password_token, :password, :password_confirmation)
      end
    end
  end
end
