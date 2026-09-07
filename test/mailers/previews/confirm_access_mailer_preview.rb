# frozen_string_literal: true

# ConfirmAccessMailer had no preview, so the mail carrying the code someone types
# back to reach their account settings could not be looked at - and
# MjmlRenderingTest, being driven off preview discovery, never checked it.
class ConfirmAccessMailerPreview < ActionMailer::Preview
  def confirm_access_email
    ConfirmAccessMailer.confirm_access_email(
      User.first || User.new(username: "Commander", email: "commander@example.com"),
      "A7X-42Q"
    )
  end
end
