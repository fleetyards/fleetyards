# frozen_string_literal: true

require "test_helper"

class AdminMailerTest < ActionMailer::TestCase
  setup do
    @super_admin = create(:admin_user, super_admin: true, email: "admin@fleetyards.test")
  end

  test "#weekly renders the subject" do
    mail = AdminMailer.weekly(@super_admin, report)
    assert_equal I18n.t(:"mailer.admin.weekly.subject"), mail.subject
  end

  test "#weekly addresses the admin it was built for" do
    mail = AdminMailer.weekly(@super_admin, report)
    assert_equal [@super_admin.email], mail.to
  end

  test "#weekly renders every section and the delta columns" do
    mail = AdminMailer.weekly(@super_admin, report)

    %i[growth engagement supporters ops content].each do |section|
      assert_includes mail.body.encoded, ERB::Util.html_escape(I18n.t(:"mailer.admin.weekly.sections.#{section}"))
    end
    assert_includes mail.body.encoded, I18n.t(:"mailer.admin.weekly.metrics.wishes")
  end

  test "#weekly lists the admins own open notifications" do
    create(:admin_notification, admin_user: @super_admin, title: "Paints Import Results")
    create(:admin_notification, admin_user: create(:admin_user), title: "Someone Elses Report")

    mail = AdminMailer.weekly(@super_admin, report)

    assert_includes mail.body.encoded, "Paints Import Results"
    assert_not_includes mail.body.encoded, "Someone Elses Report"
  end

  test "#weekly leaves out the digest notification it is about to create" do
    create(:admin_notification, admin_user: @super_admin, notification_type: "weekly_stats", title: "Weekly Report")

    mail = AdminMailer.weekly(@super_admin, report)

    assert_includes mail.body.encoded, I18n.t(:"mailer.admin.weekly.notifications.empty")
  end

  test "#new_supporter renders the subject" do
    mail = AdminMailer.new_supporter(supporter)
    assert_equal I18n.t(:"mailer.admin.new_supporter.subject"), mail.subject
  end

  test "#new_supporter sends to super admin users" do
    mail = AdminMailer.new_supporter(supporter)
    assert_includes mail.to, @super_admin.email
  end

  test "#new_supporter renders the body" do
    mail = AdminMailer.new_supporter(supporter)
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

  def report
    @report ||= AdminWeeklyReport.build
  end

  def supporter
    create(:supporter_contribution, :patreon, name: "Alice", amount_cents: 500, currency: "EUR")
  end
end
