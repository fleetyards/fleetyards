# frozen_string_literal: true

require "test_helper"

class AdminMailerTest < ActionMailer::TestCase
  setup do
    @super_admin = create(:admin_user, super_admin: true, email: "admin@fleetyards.test")
  end

  test "#weekly renders the subject" do
    mail = AdminMailer.weekly(weekly_stats)
    assert_equal I18n.t(:"mailer.admin.weekly.subject"), mail.subject
  end

  test "#weekly sends to super admin users" do
    mail = AdminMailer.weekly(weekly_stats)
    assert_includes mail.to, @super_admin.email
  end

  test "#weekly renders the body" do
    mail = AdminMailer.weekly(weekly_stats)
    assert mail.body.encoded.present?
  end

  test "#notify_block renders the subject" do
    mail = AdminMailer.notify_block("https://robertsspaceindustries.com")
    assert_equal I18n.t(:"mailer.admin.notify_block.subject"), mail.subject
  end

  test "#notify_block sends to super admin users" do
    mail = AdminMailer.notify_block("https://robertsspaceindustries.com")
    assert_includes mail.to, @super_admin.email
  end

  test "#notify_block renders the body" do
    mail = AdminMailer.notify_block("https://robertsspaceindustries.com")
    assert mail.body.encoded.present?
  end

  test "#notify_unblock renders the subject" do
    mail = AdminMailer.notify_unblock("https://robertsspaceindustries.com")
    assert_equal I18n.t(:"mailer.admin.notify_block.subject"), mail.subject
  end

  test "#notify_unblock sends to super admin users" do
    mail = AdminMailer.notify_unblock("https://robertsspaceindustries.com")
    assert_includes mail.to, @super_admin.email
  end

  test "#notify_unblock renders the body" do
    mail = AdminMailer.notify_unblock("https://robertsspaceindustries.com")
    assert mail.body.encoded.present?
  end

  private

  def weekly_stats
    {registrations: 10, ships: 5, vehicles: 20, fleets: 2}
  end
end
