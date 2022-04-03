# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: Rails.configuration.app.mailer_default_from.to_s

  layout 'mailer'

  rescue_from Postmark::InactiveRecipientError, :handle_inactive_error

  private def handle_inactive_error
    message.to.each do |email|
      EmailRejection.find_or_create_by(email: email)
    end
  end
end
