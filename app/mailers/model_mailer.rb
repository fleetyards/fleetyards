# frozen_string_literal: true

class ModelMailer < ApplicationMailer
  default from: Rails.application.secrets[:mailer_default_from].to_s

  def notify_admin(model)
    @model = model
    mail(
      to: Rails.application.secrets[:mailer_admin_mail],
      subject: I18n.t(:"mailer.model.admin.subject"),
      template_name: 'admin'
    )
  end
end
