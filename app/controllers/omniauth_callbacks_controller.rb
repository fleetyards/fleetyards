class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # See https://github.com/omniauth/omniauth/wiki/FAQ#rails-session-is-clobbered-after-callback-on-developer-strategy
  skip_before_action :verify_authenticity_token, only: %i[discord]

  def discord
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user.present?
      sign_in(:user, @user)
      redirect_to frontend_root_path(reload_session: true)

      set_flash_message(:notice, :success, kind: "Discord") if is_navigational_format?
    else
      set_flash_message(:alert, :failure, kind: "Discord", reason: "user not found") if is_navigational_format?
      session["devise.discord_data"] = request.env["omniauth.auth"].except(:extra) # Removing extra as it can overflow some session stores
      redirect_to frontend_login_path
    end
  end

  def failure
    redirect_to frontend_root_path
  end
end
