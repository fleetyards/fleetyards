# frozen_string_literal: true

# Fleet notifications whose stored text says everything: the title, the body
# and the link are the same ones the app shows.
class FleetMailer < ApplicationMailer
  helper MarkdownHelper

  def fleet_notification(notification)
    @notification = notification
    @user = notification.user
    @link = "#{FRONTEND_ENDPOINT}#{notification.link}" if notification.link.present?

    mail(to: @user.email, subject: notification.title)
  end
end
