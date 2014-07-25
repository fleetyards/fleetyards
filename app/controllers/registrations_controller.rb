class RegistrationsController < Devise::RegistrationsController
  before_action :check_registration_setting, only: [:new, :create]

  def new
    @active_nav = 'registration'
  end

  def edit
    @active_nav = 'users'
    authorize! :update, user
  end

  def update
    @active_nav = 'users'
    authorize! :update, user
    if user.update_without_password(user_params)
      redirect_to edit_user_registration_path, notice: I18n.t(:"messages.update.success", resource: I18n.t(:"resources.messages.user_data"))
    else
      render "edit", error: I18n.t(:"messages.update.failure", resource: I18n.t(:"resources.messages.user_data"))
    end
  end

  private def user_params
    @user_params ||= params.require(:user).permit(:locale, :username, :email, :gravatar, :remember_me, address_attributes: [:company, :name, :address, :country, :email, :telefon, :fax, :website])
  end

  private def user
    @user ||= current_user
    @user ||= User.new
  end
  helper_method :user

  private def check_registration_setting
    redirect_to root_path unless registration_enabled?
  end
end
