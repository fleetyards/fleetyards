# frozen_string_literal: true

class ModelMailer < ApplicationMailer
  def notify_new(to, model)
    @model = model

    mail(
      to: to,
      subject: I18n.t(:'mailer.model.new.subject'),
      message_stream: 'broadcast'
    )
  end
end
