# frozen_string_literal: true

class AdminMailer < ApplicationMailer
  default from: Rails.application.secrets[:mailer_default_from].to_s

  def weekly(stats)
    @stats = stats

    mail(
      to: Rails.application.secrets[:admin_mail],
      subject: I18n.t(:"mailer.admin.weekly.subject")
    )
  end

  def missing_loaners(loaners)
    @loaners = loaners

    mail(
      to: Rails.application.secrets[:admin_mail],
      subject: I18n.t(:"mailer.admin.missing_loaners.subject")
    )
  end

  def notify_block(url)
    @url = url

    mail(
      to: Rails.application.secrets[:admin_mail],
      subject: I18n.t(:"mailer.admin.notify_block.subject")
    )
  end

  def notify_unblock(url)
    @url = url

    mail(
      to: Rails.application.secrets[:admin_mail],
      subject: I18n.t(:"mailer.admin.notify_block.subject")
    )
  end
end
