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

  # The whole of the report's phone layout is four percentage widths under one
  # table-layout declaration, and both have to survive two passes that rewrite
  # tables for a living - MRML compiling mj-table, then premailer inlining and
  # merging every rule it can reach. Neither a pixel width creeping back nor
  # table-layout going missing raises anything. It just hands the three figure
  # columns a fixed 270px, which on a phone leaves the metric name about 38 and
  # brings "New Registrations" down the page one character per line.
  test "#weekly sizes the report columns in shares rather than pixels" do
    html = delivered_html(AdminMailer.weekly(@super_admin, report))

    fixed = html.scan(/table-layout:\s*fixed/i)
    assert_equal report[:sections].size, fixed.size,
      "expected one fixed-layout table per report section, found #{fixed.size}. Without " \
      "table-layout the client re-measures each column against its contents and the " \
      "shares declared below stop meaning anything. (This admin has no open " \
      "notifications here - giving them one adds that table to the count too.)"

    headers = html.scan(/<th[^>]*style="([^"]*)"/i).flatten
    refute_empty headers, "the report tables rendered no header cells to size"

    shares = headers.map { |style| style[/width:\s*([\d.]+)%/, 1]&.to_f }
    assert_not_includes shares, nil,
      "a report header cell declares no percentage width: #{headers.inspect}. A pixel " \
      "width is exactly what this test exists to catch."

    assert_equal 0, shares.size % 4, "expected four header cells per section table"
    shares.each_slice(4) do |section|
      assert_in_delta 100.0, section.sum, 0.01,
        "a section's column shares add up to #{section.sum}%, not 100: #{section.inspect}"
    end
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

  # premailer only runs in its delivery hook, so the markup a recipient actually
  # gets does not exist until the hook has. Calling it directly keeps this off
  # the network, which a real deliver_now would need for the asset hosts.
  def delivered_html(mail)
    Premailer::Rails::Hook.delivering_email(mail)
    part = mail.parts.find { |p| p.content_type.to_s.start_with?("text/html") }
    assert part, "the mail has no text/html part"
    part.body.decoded
  end

  def report
    @report ||= AdminWeeklyReport.build
  end

  def supporter
    create(:supporter_contribution, :patreon, name: "Alice", amount_cents: 500, currency: "EUR")
  end
end
