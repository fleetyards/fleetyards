# frozen_string_literal: true

class DeviseMailerPreview < ActionMailer::Preview
  def confirmation_instructions
    Devise::Mailer.confirmation_instructions(user, "faketoken")
  end

  # Deliberately a new record rather than `user`: this is the variant sent when
  # someone changes their address, which the template branches on through
  # unconfirmed_email?.
  def email_confirmation_instructions
    Devise::Mailer.confirmation_instructions(
      User.new(unconfirmed_email: "foo@bar.de", username: "Jean Luc"),
      "faketoken"
    )
  end

  def email_changed
    Devise::Mailer.email_changed(user)
  end

  def password_change
    Devise::Mailer.password_change(user)
  end

  def reset_password_instructions
    Devise::Mailer.reset_password_instructions(user, "faketoken")
  end

  # Every preview here used to raise "Please Create a User" on a database with no
  # users, which is every fresh worktree. A real one is still preferred so the
  # mail shows a real username and address.
  private def user
    User.first || User.new(username: "Jean Luc", email: "jean.luc@example.com")
  end
end
