# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: Rails.configuration.app.mailer_default_from.to_s

  layout "mailer"

  private def handle_inactive_error
    message.to.each do |email|
      EmailRejection.find_or_create_by(email:)
    end
  end
end
