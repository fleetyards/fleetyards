# frozen_string_literal: true

module Api
  module V1
    class SessionsController < ::Api::BaseController
      include AccessConfirmable

      skip_verify_authorized except: [:confirm_access, :send_confirm_access_email, :verify_confirm_access_code]

      # A sign-in replaces whoever the session held, so nothing may fetch them
      # first: a timed out user would answer with a 401, and a remember cookie
      # would sign the previous account back in and make `sign_in` a no-op.
      prepend_before_action(only: :create) { warden.logout(:user) }
      skip_before_action :set_paper_trail_whodunnit, :write_session_when_signed_in, :set_last_active_at, only: :create

      # As Devise's own sessions controller does: a sign-out ends a timed out
      # session too, rather than answering 401 and leaving it in place.
      prepend_before_action(only: :destroy) { request.env["devise.skip_timeout"] = true }

      before_action :authenticate_user!, except: [:create, :confirm_access]
      before_action -> { doorkeeper_authorize! }, unless: -> { warden.authenticate?(scope: :user) }, only: [:confirm_access]
      before_action :set_user, only: [:confirm_access, :send_confirm_access_email, :verify_confirm_access_code]

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
        write_session

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

        confirmation_code = SecureRandom.random_number(10**6).to_s.rjust(6, "0")
        token = access_confirmation_verifier.generate(
          {user_id: user.id, code: confirmation_code},
          expires_in: 10.minutes
        )
        ConfirmAccessMailer.confirm_access_email(user, confirmation_code).deliver_later

        render json: {code: :success, message: I18n.t("messages.confirmAccessEmail.sent"), token:}
      end

      def verify_confirm_access_code
        user = current_resource_owner

        payload = access_confirmation_verifier.verified(params[:token])&.with_indifferent_access

        if payload.blank? || payload[:user_id] != user.id || payload[:code] != params[:confirmation_code]
          render json: {code: "session.confirmAccessCode.failure", message: I18n.t("messages.confirmAccessCode.failure")}, status: :bad_request
          return
        end

        result = issue_access_confirmation(user)
        render json: {code: :success, message: I18n.t("labels.success"), **result}
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
