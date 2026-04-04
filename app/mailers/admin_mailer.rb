# frozen_string_literal: true

class AdminMailer < ApplicationMailer
  def weekly(stats)
    @stats = stats

    mail(
      to: super_admin_emails,
      subject: I18n.t(:"mailer.admin.weekly.subject")
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
end
