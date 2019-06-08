# frozen_string_literal: true

class RoadmapMailer < ApplicationMailer
  default from: Rails.application.secrets[:mailer_default_from].to_s

  def notify_admin(changes)
    @changes = changes
    mail(
      to: Rails.application.secrets[:mailer_admin_mail],
      subject: I18n.t(:"mailer.roadmap.admin.subject")
    )
  end
end
