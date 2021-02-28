# frozen_string_literal: true

class ProgressTrackerMailer < ApplicationMailer
  def notify_admin(changes)
    @changes = changes

    mail(
      to: Rails.application.secrets[:admin_mail],
      subject: I18n.t(:"mailer.progress_tracker.admin.subject")
    )
  end
end
