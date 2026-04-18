# frozen_string_literal: true

module Api
  module V1
    class SessionsController < ::Api::BaseController
      include AccessConfirmable

      skip_verify_authorized except: [:confirm_access, :send_confirm_access_email, :verify_confirm_access_email]

      before_action :authenticate_user!, except: [:create, :confirm_access, :verify_confirm_access_email]
      before_action -> { doorkeeper_authorize! }, unless: -> { warden.authenticate?(scope: :user) }, only: [:confirm_access]
      before_action :set_user, only: [:confirm_access, :send_confirm_access_email]

      def create
        resource = User.find_for_database_authentication(login: login_params[:login])

        if resource.blank?
          render json: {code: "session.create.not_found_in_database", message: I18n.t("devise.failure.not_found_in_database")}, status: :bad_request
          return
        else
          unless resource.active_for_authentication?
            resource.resend_confirmation

            render json: {code: "session.create.unconfirmed", message: I18n.t("devise.failure.unconfirmed")}, status: :bad_request
            return
          end

          if resource.otp_required_for_login && login_params[:two_factor_code].blank?
            render json: {code: "session.create.two_factor_required", message: I18n.t("devise.failure.two_factor_required")}, status: :bad_request
            return
          end

          unless resource.valid_password?(login_params[:password])
            render json: {code: "session.create.invalid", message: I18n.t("devise.failure.not_found_in_database")}, status: :bad_request
            return
          end

          if resource.otp_required_for_login && !resource.validate_and_consume_otp!(login_params[:two_factor_code])
            if resource.invalidate_otp_backup_code!(login_params[:two_factor_code])
              resource.save!
            else
              render json: {code: "session.create.invalid", message: I18n.t("devise.failure.two_factor_invalid")}, status: :bad_request
              return
            end
          end
        end

        resource.remember_me = login_params[:remember_me]

        sign_in(:user, resource)

        @user = resource

        render "api/v1/users/me"
      end

      def destroy
        sign_out(:user)

        render json: {code: "sessions.destroy", message: I18n.t("devise.sessions.signed_out")}
      end

      def confirm_access
        user = current_resource_owner

        unless user.valid_password?(login_params[:password])
          render json: {code: "session.confirmAccess.failure", message: I18n.t("messages.confirmAccess.failure")}, status: :bad_request
          return
        end

        result = issue_access_confirmation(user)
        render json: {code: :success, message: I18n.t("labels.success"), **result}
      end

      def send_confirm_access_email
        user = current_resource_owner

        unless user.oauth_only?
          render json: {code: "session.confirmAccessEmail.notAllowed", message: I18n.t("messages.confirmAccessEmail.notAllowed")}, status: :forbidden
          return
        end

        redirect_path = params[:redirect_path].presence || "account"

        token = access_confirmation_verifier.generate(
          {user_id: user.id, redirect_path:},
          expires_in: 15.minutes
        )
        ConfirmAccessMailer.confirm_access_email(user, token).deliver_now

        render json: {code: :success, message: I18n.t("messages.confirmAccessEmail.sent")}
      end

      def verify_confirm_access_email
        payload = access_confirmation_verifier.verified(params[:token])

        if payload.blank? || payload[:user_id].blank?
          redirect_to frontend_settings_account_url(access_confirmed: "invalid"), allow_other_host: true
          return
        end

        user = User.find_by(id: payload[:user_id])

        if user.blank?
          redirect_to frontend_settings_account_url(access_confirmed: "invalid"), allow_other_host: true
          return
        end

        sign_in(:user, user) unless warden.authenticate?(scope: :user)

        cookies.encrypted["#{Rails.configuration.cookie_prefix}_ACCESS_CONFIRMED"] = {
          value: user.confirm_access_token,
          domain: Rails.configuration.app.cookie_domain,
          secure: Rails.env.production? || Rails.env.staging?,
          expires: 15.minutes,
          httponly: true,
          same_site: :lax
        }

        redirect_path = payload[:redirect_path].presence || "account"
        redirect_url = (redirect_path == "security") ? frontend_security_settings_url : frontend_settings_account_url
        redirect_to "#{redirect_url}?access_confirmed=true", allow_other_host: true
      end

      private def set_user
        @user = current_resource_owner

        authorize! @user
      end

      private def login_params
        @login_params ||= params.permit(:login, :password, :remember_me, :two_factor_code)
      end
    end
  end
end
