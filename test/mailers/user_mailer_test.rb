# frozen_string_literal: true

require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  test "#username_changed renders the subject" do
    mail = UserMailer.username_changed("user@example.com", "testuser")
    assert_equal I18n.t(:"mailer.user.username_changed.subject"), mail.subject
  end

  test "#username_changed sends to the correct recipient" do
    mail = UserMailer.username_changed("user@example.com", "testuser")
    assert_equal ["user@example.com"], mail.to
  end

  test "#username_changed renders the body" do
    mail = UserMailer.username_changed("user@example.com", "testuser")
    assert mail.body.encoded.present?
  end
end
