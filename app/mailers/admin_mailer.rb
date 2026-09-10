# frozen_string_literal: true

class AdminMailer < ApplicationMailer
  helper AdminReportHelper

  # Every mail in here goes to an AdminUser, so it comes from the same place the
  # admin app does and wears the same accent. See themes.scss for why that is a
  # violet: it was chosen for distance from every colour the app already assigns
  # a meaning to, and its contrast profile matches the blue it stands in for.
  self.mail_theme = :admin

  OPEN_NOTIFICATIONS_LIMIT = 10

  # Sent per admin rather than to the whole super-admin list at once: the digest
  # ends on the recipient's own open notifications, which no shared mail can show.
  def weekly(admin_user, report)
    @admin_user = admin_user
    @report = report
    @notifications = open_notifications_for(admin_user)
    @notifications_url = "#{ADMIN_ENDPOINT}/notifications"

    mail(
      to: admin_user.email,
      subject: I18n.t(:"mailer.admin.weekly.subject")
    )
  end

  def new_supporter(supporter)
    @supporter = supporter

    mail(
      to: super_admin_emails,
      subject: I18n.t(:"mailer.admin.new_supporter.subject")
    )
  end

  def notify_block(url)
    @url = url

    mail(
      to: super_admin_emails,
      subject: I18n.t(:"mailer.admin.notify_block.subject")
    )
  end

  def notify_unblock(url)
    @url = url

    mail(
      to: super_admin_emails,
      subject: I18n.t(:"mailer.admin.notify_block.subject")
    )
  end

  private def super_admin_emails
    AdminUser.where(super_admin: true).pluck(:email)
  end

  private def open_notifications_for(admin_user)
    AdminNotification.where(admin_user:)
      .active
      .unread
      .where.not(notification_type: :weekly_stats)
      .order(created_at: :desc)
      .limit(OPEN_NOTIFICATIONS_LIMIT)
  end
end
