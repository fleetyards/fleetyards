# frozen_string_literal: true

module Admin
  class AdminUsersController < ::Admin::ApplicationController
    before_action :set_active_nav
    after_action :save_filters, only: [:index]

    def index
      authorize! :index, :admin_users
      @q = AdminUser.ransack(params[:q])
      @admin_users = @q.result
        .page(params.fetch(:page) { nil })
        .per(40)
    end

    def new
      authorize! :create, :admin_users
      @user = AdminUser.new
    end

    def create
      authorize! :create, :admin_users
      @admin_user = AdminUser.new(admin_user_params)
      if admin_user.save
        redirect_to admin_admins_path(params: index_back_params, anchor: admin_user.id), notice: I18n.t(:"messages.create.success", resource: I18n.t(:"resources.admin_user"))
      else
        render 'new', error: I18n.t(:"messages.create.failure", resource: I18n.t(:"resources.admin_user"))
      end
    end

    def edit
      authorize! :update, admin_user
    end

    def update
      authorize! :update, admin_user
      if admin_user.update(admin_user_params)
        redirect_to admin_admins_path(params: index_back_params, anchor: admin_user.id), notice: I18n.t(:"messages.update.success", resource: I18n.t(:"resources.admin_user"))
      else
        render 'edit', error: I18n.t(:"messages.update.failure", resource: I18n.t(:"resources.user"))
      end
    end

    def destroy
      authorize! :destroy, admin_user
      if admin_user.destroy
        redirect_to admin_admins_path(params: index_back_params), notice: I18n.t(:"messages.destroy.success", resource: I18n.t(:"resources.admin_user"))
      else
        redirect_to admin_admins_path(params: index_back_params, anchor: admin_user.id), error: I18n.t(:"messages..destroy.failure", resource: I18n.t(:"resources.admin_user"))
      end
    end

    def resend_confirmation
      authorize! :update, admin_user
      if admin_user.resend_confirmation_instructions
        redirect_to admin_admins_path(params: index_back_params, anchor: admin_user.id), notice: I18n.t(:"messages.resend_confirmation.success", resource: I18n.t(:"resources.admin_user"))
      else
        redirect_to admin_admins_path(params: index_back_params, anchor: admin_user.id), notice: I18n.t(:"messages.resend_confirmation.failure", resource: I18n.t(:"resources.admin_user"))
      end
    end

    private def admin_user_params
      @admin_user_params ||= params.require(:user).permit(
        :username, :email, :password, :password_confirmation
      )
    end

    private def save_filters
      session[:admin_users_filters] = query_params(
        :email_cont, :username_cont
      ).to_h
      session[:admin_users_page] = params[:page]
    end

    private def index_back_params
      @index_back_params ||= ActionController::Parameters.new(
        q: session[:admin_users_filters],
        page: session[:admin_users_page]
      ).permit!.delete_if { |_k, v| v.nil? }
    end
    helper_method :index_back_params

    private def admin_user
      @admin_user ||= AdminUser.where(id: params.fetch(:id, nil)).first
    end
    helper_method :admin_user

    private def set_active_nav
      @active_nav = 'admin-admin_users'
    end
  end
end
