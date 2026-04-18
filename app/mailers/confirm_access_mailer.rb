# frozen_string_literal: true

class ConfirmAccessMailer < ApplicationMailer
  def confirm_access_email(user, confirmation_code)
    @username = user.username
    @confirmation_code = confirmation_code

    mail(
      to: user.email,
      subject: I18n.t(:"mailer.confirm_access.subject")
    )
  end
end
