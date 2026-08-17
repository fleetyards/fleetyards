# frozen_string_literal: true

class AdminMailerPreview < ActionMailer::Preview
  def weekly
    AdminMailer.weekly(AdminUser.where(super_admin: true).first || AdminUser.first, AdminWeeklyReport.build)
  end

  def notify_block
    AdminMailer.notify_block("https://foo.bar")
  end

  def notify_unblock
    AdminMailer.notify_unblock("https://foo.bar")
  end
end
