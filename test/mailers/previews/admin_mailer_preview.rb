# frozen_string_literal: true

class AdminMailerPreview < ActionMailer::Preview
  def weekly
    AdminMailer.weekly(admin_user, AdminWeeklyReport.build)
  end

  # new_supporter had no preview either, so its template went unchecked.
  def new_supporter
    AdminMailer.new_supporter(
      SupporterContribution.first ||
        SupporterContribution.new(name: "Commander", amount_cents: 2500, currency: "EUR")
    )
  end

  def notify_block
    AdminMailer.notify_block("https://foo.bar")
  end

  def notify_unblock
    AdminMailer.notify_unblock("https://foo.bar")
  end

  # A database with no admin users - every fresh worktree - left this nil and the
  # preview died on admin_user.email. The stand-in is unsaved on purpose: the
  # mailer scopes its open-notifications query by admin_user, and a record with
  # no id matches nothing, so the digest renders its empty state rather than
  # another admin's notifications.
  private def admin_user
    AdminUser.where(super_admin: true).first ||
      AdminUser.first ||
      AdminUser.new(email: "admin@example.com")
  end
end
