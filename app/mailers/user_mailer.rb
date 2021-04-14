# frozen_string_literal: true

class UserMailer < ApplicationMailer
  def username_changed(to, username)
    @username = username

    mail(
      to: to,
      subject: I18n.t(:"mailer.user.username_changed.subject")
    )
  end
end
