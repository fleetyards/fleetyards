# encoding: utf-8
# frozen_string_literal: true

class Devise::MailerPreview < ActionMailer::Preview # rubocop:disable Style/ClassAndModuleChildren
  def confirmation_instructions
    user = User.first
    raise 'Please Create a User' if user.nil?
    Devise::Mailer.confirmation_instructions(user, "faketoken")
  end

  def reset_password_instructions
    user = User.first
    raise 'Please Create a User' if user.nil?
    Devise::Mailer.reset_password_instructions(user, "faketoken")
  end
end
