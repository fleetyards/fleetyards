# frozen_string_literal: true

class RoadmapMailer < AdminMailer
  def notify_admin(changes)
    @changes = changes

    mail(
      subject: I18n.t(:"mailer.roadmap.admin.subject")
    )
  end
end
