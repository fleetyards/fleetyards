class RegistrationsController < Devise::RegistrationsController
  before_action :check_registration_setting, only: [:new, :create]

  def new
    @user = build_user
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
    @user_params ||= params.require(:user).permit(:locale, :username, :email,
      :gravatar, :remember_me, :rsi_organization_url, :rsi_profile_url
    )
  end

  private def build_user(hash = {})
    User.new_with_session(hash, session)
  end

  private def user
    @user ||= current_user
    @user ||= build_user(user_params)
  end
  helper_method :user

  private def locales
    @locales ||= I18n.available_locales.map do |locale|
      OpenStruct.new({
        id: locale,
        name: I18n.t(:"locales.#{locale}")
      })
    end
  end
  helper_method :locales

  private def check_registration_setting
    redirect_to root_path unless registration_enabled?
  end
end
