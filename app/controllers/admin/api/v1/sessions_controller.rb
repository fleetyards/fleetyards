# frozen_string_literal: true

module Admin
  module Api
    module V1
      class SessionsController < ::Admin::Api::BaseController
        skip_verify_authorized

        before_action :authenticate_admin_user!, except: [:create]

        def create
          resource = AdminUser.find_for_database_authentication(login: login_params[:login])

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

          sign_in(:admin_user, resource)

          render json: {code: :success, message: I18n.t("labels.success")}
        end

        def destroy
          sign_out(:user)

          render json: {code: "sessions.destroy", message: I18n.t("devise.sessions.signed_out")}
        end

        private def login_params
          @login_params ||= params.permit(:login, :password, :remember_me, :two_factor_code)
        end
      end
    end
  end
end
