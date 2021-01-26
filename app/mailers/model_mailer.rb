# frozen_string_literal: true

class ModelMailer < ApplicationMailer
  default from: Rails.application.secrets[:mailer_default_from].to_s

  def notify_new(to, model)
    @model = model

    mail(
      to: to,
      subject: I18n.t(:"mailer.model.new.subject")
    )
  end
end
