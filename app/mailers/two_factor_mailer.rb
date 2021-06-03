# frozen_string_literal: true

class TwoFactorMailer < ApplicationMailer
  def login(to, token)
    @two_factor_code = token

    mail(
      to: to,
      subject: I18n.t(:'mailer.two_factor.login.subject')
    )
  end

  def enabled(to, username)
    @username = username

    mail(
      to: to,
      subject: I18n.t(:'mailer.two_factor.enabled.subject')
    )
  end

  def disabled(to, username)
    @username = username

    mail(
      to: to,
      subject: I18n.t(:'mailer.two_factor.disabled.subject')
    )
  end
end
