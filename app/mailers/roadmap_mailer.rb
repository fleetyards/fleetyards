# frozen_string_literal: true

class RoadmapMailer < ApplicationMailer
  def notify_admin(changes)
    @changes = changes

    mail(
      to: Rails.application.secrets[:admin_mail],
      subject: I18n.t(:"mailer.roadmap.admin.subject")
    )
  end
end
