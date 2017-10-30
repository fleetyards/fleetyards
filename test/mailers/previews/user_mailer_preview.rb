# frozen_string_literal: true

class UserMailerPreview < ActionMailer::Preview
  def notify_admin
    user = User.first
    raise 'Please Create a User' if user.nil?
    UserMailer.notify_admin(user)
  end
end
