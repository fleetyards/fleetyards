# frozen_string_literal: true

class TwoFactorMailerPreview < ActionMailer::Preview
  def login
    TwoFactorMailer.login('foo@bar.de', '123456')
  end

  def enabled
    TwoFactorMailer.enabled('foo@bar.de', 'John Doe')
  end

  def disabled
    TwoFactorMailer.disabled('foo@bar.de', 'John Doe')
  end
end
