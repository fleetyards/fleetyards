# frozen_string_literal: true

class AdminMailer < ApplicationMailer
  default to: Rails.configuration.app.mailer_default_admin_to.to_s

  def weekly(stats)
    @stats = stats

    mail(
      subject: I18n.t(:'mailer.admin.weekly.subject')
    )
  end

  def missing_loaners(loaners, models)
    @missing_loaners = loaners
    @missing_models = models

    mail(
      subject: I18n.t(:'mailer.admin.missing_loaners.subject')
    )
  end

  def notify_block(url)
    @url = url

    mail(
      subject: I18n.t(:'mailer.admin.notify_block.subject')
    )
  end

  def notify_unblock(url)
    @url = url

    mail(
      subject: I18n.t(:'mailer.admin.notify_block.subject')
    )
  end
end
