# frozen_string_literal: true

class AdminMailer < ApplicationMailer
  default from: Rails.application.secrets[:mailer_default_from].to_s

  def weekly(stats)
    @stats = stats
    mail(
      to: Rails.application.secrets[:mailer_admin_mail],
      subject: I18n.t(:"mailer.admin.weekly.subject")
    )
  end

  def notify_block
    mail(
      to: Rails.application.secrets[:mailer_admin_mail],
      subject: I18n.t(:"mailer.admin.notify_block.subject")
    )
  end
end
