# frozen_string_literal: true

module Admin
  class UsersController < ::Admin::ApplicationController
    before_action :set_active_nav
    after_action :save_filters, only: [:index]

    def index
      authorize! :index, :admin_users
      @q = User.ransack(params[:q])
      @users = @q.result
        .page(params.fetch(:page) { nil })
        .per(40)
    end

    def new
      authorize! :create, :admin_users
      @user = User.new
    end

    def create
      authorize! :create, :admin_users
      @user = User.new(user_params)
      if user.save
        redirect_to admin_users_path(params: index_back_params, anchor: user.id), notice: I18n.t(:'messages.create.success', resource: I18n.t(:'resources.user'))
      else
        render 'new', error: I18n.t(:'messages.create.failure', resource: I18n.t(:'resources.user'))
      end
    end

    def edit
      authorize! :update, user
    end

    def update
      authorize! :update, user
      if user.update(user_params)
        redirect_to admin_users_path(params: index_back_params, anchor: user.id), notice: I18n.t(:'messages.update.success', resource: I18n.t(:'resources.user'))
      else
        render 'edit', error: I18n.t(:'messages.update.failure', resource: I18n.t(:'resources.user'))
      end
    end

    def destroy
      authorize! :destroy, user
      if user.destroy
        redirect_to admin_users_path(params: index_back_params, anchor: user.id), notice: I18n.t(:'messages.destroy.success', resource: I18n.t(:'resources.user'))
      else
        redirect_to admin_users_path(params: index_back_params, anchor: user.id), error: I18n.t(:'messages..destroy.failure', resource: I18n.t(:'resources.user'))
      end
    end

    def resend_confirmation
      authorize! :update, user
      if user.resend_confirmation_instructions
        redirect_to admin_users_path(params: index_back_params, anchor: user.id), notice: I18n.t(:'messages.resend_confirmation.success', resource: I18n.t(:'resources.user'))
      else
        redirect_to admin_users_path(params: index_back_params, anchor: user.id), notice: I18n.t(:'messages.resend_confirmation.failure', resource: I18n.t(:'resources.user'))
      end
    end

    def login_as
      authorize! :update, user

      sign_in(:user, user)

      redirect_to frontend_root_url(reload_session: true)
    end

    private def user_params
      @user_params ||= params.require(:user).permit(
        :admin, :username, :email, :password, :password_confirmation
      )
    end

    private def save_filters
      session[:users_filters] = query_params(
        :email_cont, :username_cont
      ).to_h
      session[:users_page] = params[:page]
    end

    private def index_back_params
      @index_back_params ||= ActionController::Parameters.new(
        q: session[:users_filters],
        page: session[:users_page]
      ).permit!.delete_if { |_k, v| v.nil? }
    end
    helper_method :index_back_params

    private def user
      @user ||= User.where(id: params.fetch(:id, nil)).first
    end
    helper_method :user

    private def set_active_nav
      @active_nav = 'admin-users'
    end
  end
end
