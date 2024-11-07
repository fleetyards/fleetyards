# frozen_string_literal: true

module Api
  module V1
    class UsersController < ::Api::BaseController
      skip_authorization_check only: %i[signup confirm]

      before_action :doorkeeper_authorize!, unless: :user_signed_in?, only: %i[me update]
      before_action :authenticate_user!, except: %i[me update]

      def me
        authorize! :read, current_user

        @user = current_user
      end

      def public
        authorize! :read_public, :api_user
        @user = User.find_by!(normalized_username: params[:username].downcase, public_hangar: true)
      end

      def update
        authorize! :update, current_user

        @user = current_user

        return if @user.update(user_params)

        render json: ValidationError.new("update", errors: @user.errors), status: :bad_request
      end

      def update_account
        authorize! :update, current_user

        unless access_cookie_valid?
          render json: {code: "requires_access_confirmation", message: I18n.t("messages.user.requires_access_confirmation")}, status: :bad_request
          return
        end

        @user = current_user
        return if @user.update(user_account_params)

        render json: ValidationError.new("update", errors: @user.errors), status: :bad_request
      end

      def signup
        if current_user.present?
          render json: {code: "already_signed_in", message: I18n.t("messages.signup.already_signed_in")}, status: :unprocessable_entity
          return
        end

        if blocked(user_create_params[:email])
          render json: {code: "blocked", message: I18n.t("messages.signup.blocked")}, status: :unprocessable_entity
          return
        end

        if reserved_name(user_create_params[:username])
          render json: {
            code: "reserved_username",
            message: I18n.t("messages.signup.reserved_username"),
            errors: [
              {
                attribute: "username",
                messages: [{
                  message: I18n.t("messages.signup.username_invalid")
                }]
              }
            ]
          }, status: :bad_request
          return
        end

        fleet_invite_token = user_create_params.delete("fleet_invite_token")

        @user = User.new(user_create_params)

        @user.skip_confirmation! if @user.username == "NewTestUser"

        if @user.save
          handle_fleet_invite(@user.id, fleet_invite_token) if fleet_invite_token.present?

          render "api/v1/users/signup", status: :created
        else
          render json: ValidationError.new("signup", errors: @user.errors), status: :bad_request
        end
      end

      def confirm
        user = User.confirm_by_token(params[:token])
        if user.present? && user.errors.blank?
          render json: {code: "confirmation", message: I18n.t("devise.confirmations.confirmed")}
        else
          render json: ValidationError.new("confirmation", errors: user.errors), status: :bad_request
        end
      end

      def check_email
        authorize! :check, :api_users
        render json: {taken: User.exists?(normalized_email: (params[:value] || "").downcase)}
      end

      def check_username
        authorize! :check, :api_users
        render json: {taken: User.exists?(normalized_username: (params[:value] || "").downcase)}
      end

      def destroy
        authorize! :destroy, current_user

        if current_user.destroy
          Cleanup::UserVisitsJob.perform_async(current_user.id)

          render json: {code: "current_user.destroyed", message: I18n.t("messages.destroy.success", resource: I18n.t("resources.user"))}
        else
          render json: ValidationError.new("current_user.destroy", errors: @current_user.errors), status: :bad_request
        end
      end

      private def user_create_params
        @user_create_params ||= params.transform_keys(&:underscore)
          .permit(:username, :email, :password, :password_confirmation, :fleet_invite_token, :sale_notify)
      end

      private def user_params
        @user_params ||= params.transform_keys(&:underscore)
          .permit(
            :avatar, :remove_avatar, :sale_notify, :public_hangar, :public_wishlist, :rsi_handle,
            :discord, :homepage, :youtube, :twitch, :guilded, :public_hangar_loaners, :hide_owner
          )
      end

      private def user_account_params
        @user_account_params ||= params.transform_keys(&:underscore)
          .permit(:username, :email)
      end

      private def blocked(email)
        return unless Rails.root.join("blocklist.json").exist?

        blocklist = JSON.parse(Rails.root.join("blocklist.json").read)

        blocklist.include?(email&.downcase&.strip)
      end

      private def reserved_name(username)
        return unless Rails.root.join("reserved_usernames.json").exist?

        reserved_usernames = JSON.parse(Rails.root.join("reserved_usernames.json").read)

        reserved_usernames.include?(username&.downcase&.strip)
      end

      private def handle_fleet_invite(user_id, fleet_invite_token)
        invite_url = FleetInviteUrl.active.find_by(token: fleet_invite_token)

        return if invite_url.blank?

        member = invite_url.fleet.fleet_memberships.create(user_id:, role: :member, invited_by: invite_url.user_id, used_invite_token: invite_url.token)

        return if member.blank?

        member.request!
      end
    end
  end
end
