# frozen_string_literal: true

class ConfirmAccessMailer < ApplicationMailer
  def confirm_access_email(user, token)
    @username = user.username
    @confirm_url = verify_confirm_access_email_api_v1_sessions_url(token:)

    mail(
      to: user.email,
      subject: I18n.t(:"mailer.confirm_access.subject")
    )
  end
end
