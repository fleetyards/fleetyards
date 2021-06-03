# frozen_string_literal: true

class ProgressTrackerMailer < AdminMailer
  def notify_admin(changes)
    @changes = changes

    mail(
      subject: I18n.t(:'mailer.progress_tracker.admin.subject')
    )
  end
end
