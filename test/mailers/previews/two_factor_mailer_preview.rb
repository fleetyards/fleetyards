# frozen_string_literal: true

class TwoFactorMailerPreview < ActionMailer::Preview
  def login
    TwoFactorMailer.login('foo@bar.de', '123456')
  end
end
