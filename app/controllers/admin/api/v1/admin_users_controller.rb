# frozen_string_literal: true

module Admin
  module Api
    module V1
      class AdminUsersController < ::Admin::Api::BaseController
        before_action :set_admin_user, only: %i[show update destroy]

        def me
          authorize! current_user, with: ::Admin::AdminUserPolicy

          @admin_user = current_user
        end

        def index
          authorize! with: ::Admin::AdminUserPolicy

          @admin_users = AdminUser.all
            .order(username: :asc)
            .page(page_params)
            .per(per_page(AdminUser))
        end

        def show
        end

        def create
          @admin_user = AdminUser.new(admin_user_params)

          authorize! @admin_user, with: ::Admin::AdminUserPolicy

          return if @admin_user.save

          render json: ValidationError.new("admin_user.create", errors: @admin_user.errors), status: :bad_request
        end

        def update
          return if @admin_user.update(admin_user_params)

          render json: ValidationError.new("admin_user.update", errors: @admin_user.errors), status: :bad_request
        end

        def destroy
          return if @admin_user.destroy

          render json: ValidationError.new("admin_user.destroy", errors: @admin_user.errors), status: :bad_request
        end

        private def set_admin_user
          @admin_user = AdminUser.find(params[:id])

          authorize! @admin_user, with: ::Admin::AdminUserPolicy
        end

        private def admin_user_params
          @admin_user_params ||= params.permit(*permitted_admin_user_attributes)
        end

        # AdminUserPolicy lets an admin edit its own record, so privileges are
        # only taken from a super admin; anyone else would grant themselves.
        private def permitted_admin_user_attributes
          attributes = %i[username email password password_confirmation]
          attributes += [:super_admin, {resource_access: []}] if current_admin_user.super_admin?
          attributes
        end
      end
    end
  end
end
