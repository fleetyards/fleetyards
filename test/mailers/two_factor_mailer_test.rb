# frozen_string_literal: true

require "test_helper"

class TwoFactorMailerTest < ActionMailer::TestCase
  test "#login renders the subject" do
    mail = TwoFactorMailer.login("user@example.com", "123456")
    assert_equal I18n.t(:"mailer.two_factor.login.subject"), mail.subject
  end

  test "#login sends to the correct recipient" do
    mail = TwoFactorMailer.login("user@example.com", "123456")
    assert_equal ["user@example.com"], mail.to
  end

  test "#login renders the body" do
    mail = TwoFactorMailer.login("user@example.com", "123456")
    assert mail.body.encoded.present?
  end

  test "#enabled renders the subject" do
    mail = TwoFactorMailer.enabled("user@example.com", "testuser")
    assert_equal I18n.t(:"mailer.two_factor.enabled.subject"), mail.subject
  end

  test "#enabled sends to the correct recipient" do
    mail = TwoFactorMailer.enabled("user@example.com", "testuser")
    assert_equal ["user@example.com"], mail.to
  end

  test "#enabled renders the body" do
    mail = TwoFactorMailer.enabled("user@example.com", "testuser")
    assert mail.body.encoded.present?
  end

  test "#disabled renders the subject" do
    mail = TwoFactorMailer.disabled("user@example.com", "testuser")
    assert_equal I18n.t(:"mailer.two_factor.disabled.subject"), mail.subject
  end

  test "#disabled sends to the correct recipient" do
    mail = TwoFactorMailer.disabled("user@example.com", "testuser")
    assert_equal ["user@example.com"], mail.to
  end

  test "#disabled renders the body" do
    mail = TwoFactorMailer.disabled("user@example.com", "testuser")
    assert mail.body.encoded.present?
  end
end
