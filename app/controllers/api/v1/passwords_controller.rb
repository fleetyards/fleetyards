# frozen_string_literal: true

module Api
  module V1
    class PasswordsController < ::Api::BaseController
      skip_authorization_check only: [:request_email, :update_with_token]
      before_action :authenticate_user!, except: [:request_email, :update_with_token]

      def request_email
        user = User.find_by(email: params[:email])

        if user.present?
          user.send_reset_password_instructions
          render json: {code: "request_pasword.success", message: I18n.t("devise.passwords.send_paranoid_instructions")}
        else
          render json: ValidationError.new("request_password"), status: :bad_request
        end
      end

      def update
        authorize! :update, current_user

        if current_user.update_with_password(change_password_params)
          render json: {code: "change_pasword.success", message: I18n.t("devise.passwords.updated_not_active")}
        else
          render json: ValidationError.new("change_pasword", errors: current_user.errors), status: :bad_request
        end
      end

      def update_with_token
        user = User.reset_password_by_token(change_password_params)

        if user.errors.blank?
          render json: {code: "change_pasword.success", message: I18n.t("devise.passwords.updated_not_active")}
        else
          render json: ValidationError.new("change_pasword", errors: user.errors), status: :bad_request
        end
      end

      private def change_password_params
        @change_password_params ||= params.transform_keys(&:underscore)
          .permit(
            :reset_password_token, :current_password, :password, :password_confirmation
          )
      end
    end
  end
end
