# frozen_string_literal: true

class UserMailerPreview < ActionMailer::Preview
  def username_changed
    UserMailer.username_changed('foo@bar.de', 'John Doe')
  end
end
