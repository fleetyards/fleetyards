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

    redirect_to frontend_sign_up_url, alert: alert, allow_other_host: true
  end

  def google
    handle_auth(t("devise.omniauth.provider.google"))
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
      redirect_to frontend_security_settings_url, notice: t("devise.omniauth.connect.already_connected", kind: kind), allow_other_host: true
      return
    end

    connection = current_user.omniauth_connections.find_or_initialize_by(
      uid: auth.uid,
      provider: auth.provider
    ) do |connection|
      connection.auth_payload = auth.to_h
    end

    if connection.save
      redirect_to frontend_security_settings_url, notice: t("devise.omniauth.connect.success", kind: kind), allow_other_host: true
    else
      alert = t("devise.omniauth.connect.failure", kind: kind)
      if Rails.env.development?
        alert = t("devise.omniauth.connect.failure_with_reason", kind: kind)
      end
      redirect_to frontend_security_settings_url, alert: alert, allow_other_host: true
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
      end

      if user.nil?
        password = Devise.friendly_token[0, 60]
        user = User.new(
          email: auth.info.email,
          username: auth.info.nickname || auth.info.name,
          password: password,
          password_confirmation: password
        )
      end

      if !user.avatar.attached? && auth.info.image.present?
        avatar_uri = URI.parse(auth.info.image)
        filename = "avatar#{File.extname(avatar_uri.path)}"
        user.avatar.attach(
          io: avatar_uri.open,
          filename: filename,
          content_type: Marcel::MimeType.for(name: filename)
        )
      end

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

        origin = request.env["omniauth.origin"]
        origin = nil if origin.blank? || [frontend_login_url, frontend_sign_up_url].include?(origin)
        redirect_to origin || user.public_hangar_url, notice: t("devise.omniauth.success", kind: kind), allow_other_host: true
      else
        url = request.env["omniauth.origin"].presence || frontend_login_url
        redirect_to url, alert: t("devise.omniauth.failure_username_taken", kind: kind), allow_other_host: true
      end
    end
  end

  private def auth
    request.env["omniauth.auth"]
  end
end
