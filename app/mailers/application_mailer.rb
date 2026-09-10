# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: Rails.configuration.app.mailer_default_from.to_s

  layout "mailer"

  # The mail equivalent of data-theme on <html>, which is how the app selects a
  # theme and how the admin layout picks up its violet accent. A mail cannot use
  # that mechanism - it has no var() any client resolves - so the mailer names
  # its theme and MailerTheme resolves the literal the layout interpolates.
  #
  # nil is the same absence data-theme has on the frontend: not a theme called
  # "default", just a document that selects none.
  class_attribute :mail_theme, default: nil

  helper_method :mail_accent

  rescue_from Postmark::InactiveRecipientError do |_exception|
    handle_inactive_error
  end

  # The one themed value a mail has. Everything else in MailerTheme is neutral
  # chrome, which a theme deliberately does not touch.
  private def mail_accent
    MailerTheme.accent(mail_theme)
  end

  private def handle_inactive_error
    message.to.each do |email|
      EmailRejection.find_or_create_by(email:)
    end
  end
end
