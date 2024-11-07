# frozen_string_literal: true

module Admin
  module Api
    module V1
      class UsersController < ::Admin::Api::BaseController
        rescue_from ActiveRecord::RecordNotFound do |_exception|
          not_found(I18n.t("messages.record_not_found.user", slug: params[:slug]))
        end

        def index
          authorize! :index, :admin_api_users

          user_query_params["sorts"] ||= sorting_params(User)

          q = User.ransack(user_query_params)

          @users = q.result(distinct: true)
            .page(params[:page])
            .per(per_page(User))
        end

        private def user_query_params
          @user_query_params ||= query_params(
            :search_cont, :username_cont, :username_eq, :email_cont, :rsi_handle_cont,
            id_in: [], username_in: [], email_in: [], rsi_handle_in: []
          )
        end
      end
    end
  end
end
