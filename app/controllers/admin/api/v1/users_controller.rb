# frozen_string_literal: true

module Admin
  module Api
    module V1
      class UsersController < ::Admin::Api::BaseController
        before_action :set_user, only: %i[show update destroy login_as resend_confirmation send_password_reset]

        rescue_from ActiveRecord::RecordNotFound do |_exception|
          not_found(I18n.t("messages.record_not_found.user", slug: params[:slug]))
        end

        def index
          authorize! with: ::Admin::UserPolicy

          user_query_params["sorts"] = sorting_params(User, user_query_params[:sorts])

          q = authorized_scope(User.all).ransack(user_query_params)

          @users = q.result(distinct: true)
            .page(params[:page])
            .per(per_page(User))
        end

        def show
        end

        def update
          return if @user.update(user_params)

          render json: ValidationError.new("user.update", errors: @user.errors), status: :bad_request
        end

        def destroy
          return if @user.destroy

          render json: ValidationError.new("user.destroy", errors: @user.errors), status: :bad_request
        end

        def login_as
          sign_in(:user, @user)

          head :no_content
        end

        def resend_confirmation
          @user.resend_confirmation_instructions

          head :no_content
        end

        def send_password_reset
          @user.send_reset_password_instructions

          head :no_content
        end

        private def set_user
          @user = User.find(params[:id])

          authorize! @user, with: ::Admin::UserPolicy
        end

        private def user_params
          @user_params ||= params.permit(
            :username, :email, :rsi_handle, :sale_notify, :public_hangar,
            :public_hangar_loaners, :public_wishlist, :hide_owner, :tester, :avatar
          )
        end

        private def user_query_params
          @user_query_params ||= params.permit(q: [
            :search_cont, :username_cont, :username_eq, :email_cont, :rsi_handle_cont, :sorts,
            id_in: [], username_in: [], email_in: [], rsi_handle_in: [], sorts: []
          ]).fetch(:q, {})
        end
      end
    end
  end
end
