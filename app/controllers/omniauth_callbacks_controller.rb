class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_forgery_protection

  def failure
    alert = t(
      "devise.omniauth.failure",
      kind: t("devise.omniauth.provider.#{failed_strategy.name}"),
      reason: failure_message
    )
    if Rails.env.development?
      alert = t(
        "devise.omniauth.failure_with_reason",
        kind: t("devise.omniauth.provider.#{failed_strategy.name}"),
        reason: failure_message
      )
    end

    redirect_to frontend_sign_up_url, alert: alert
  end

  def google_oauth2
    handle_auth(t("devise.omniauth.provider.google_oauth2"))
  end

  def discord
    handle_auth(t("devise.omniauth.provider.discord"))
  end

  def github
    handle_auth(t("devise.omniauth.provider.github"))
  end

  def twitch
    handle_auth(t("devise.omniauth.provider.twitch"))
  end

  def bluesky
    handle_auth(t("devise.omniauth.provider.bluesky"))
  end

  private def handle_connect(kind)
    if current_user.omniauth_connections.exists?(provider: auth.provider, uid: auth.uid)
      redirect_to frontend_security_settings_url, notice: t("devise.omniauth.connect.already_connected", kind: kind)
      return
    end

    connection = current_user.omniauth_connections.find_or_initialize_by(
      uid: auth.uid,
      provider: auth.provider
    ) do |connection|
      connection.auth_payload = auth.to_h
    end

    if connection.save
      redirect_to frontend_security_settings_url, notice: t("devise.omniauth.connect.success", kind: kind)
    else
      alert = t("devise.omniauth.connect.failure", kind: kind)
      if Rails.env.development?
        alert = t("devise.omniauth.connect.failure_with_reason", kind: kind)
      end
      redirect_to frontend_security_settings_url, alert: alert
    end
  end

  private def handle_auth(kind)
    if current_user.present?
      handle_connect(kind)
    else
      connection = OmniauthConnection.find_by(uid: auth.uid, provider: auth.provider)

      user = if connection.present?
        User.find_by(id: connection.user_id)
      elsif auth.info.email.present?
        User.find_by(normalized_email: auth.info.email.downcase)
      else
        password = Devise.friendly_token[0, 60]
        User.new(
          email: auth.info.email,
          username: auth.info.nickname || auth.info.name,
          password: password,
          password_confirmation: password
        )
      end

      user.remote_avatar_url = auth.info.image if user.avatar.blank? && auth.info.image.present?

      user.skip_reconfirmation!

      if user.save
        if connection.blank?
          user.omniauth_connections.create!(
            uid: auth.uid,
            provider: auth.provider,
            auth_payload: auth.to_h
          )
        end

        user.remember_me = true

        sign_in(:user, user)

        redirect_to frontend_sign_up_auth_callback_url, notice: t("devise.omniauth.success", kind: kind)
      else
        url = request.env["omniauth.origin"].presence || frontend_login_url
        redirect_to url, alert: t("devise.omniauth.failure_username_taken", kind: kind)
      end
    end
  end

  private def auth
    request.env["omniauth.auth"]
  end
end
