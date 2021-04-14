# frozen_string_literal: true

class DeviseMailerPreview < ActionMailer::Preview
  def confirmation_instructions
    user = User.first
    raise 'Please Create a User' if user.nil?

    Devise::Mailer.confirmation_instructions(user, 'faketoken')
  end

  def email_confirmation_instructions
    user = User.new(unconfirmed_email: 'foo@bar.de', username: 'Jean Luc')

    Devise::Mailer.confirmation_instructions(user, 'faketoken')
  end

  def email_changed
    user = User.first
    raise 'Please Create a User' if user.nil?

    Devise::Mailer.email_changed(user)
  end

  def password_change
    user = User.first
    raise 'Please Create a User' if user.nil?

    Devise::Mailer.password_change(user)
  end

  def reset_password_instructions
    user = User.first
    raise 'Please Create a User' if user.nil?

    Devise::Mailer.reset_password_instructions(user, 'faketoken')
  end
end
