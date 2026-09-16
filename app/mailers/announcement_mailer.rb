# frozen_string_literal: true

class AnnouncementMailer < ApplicationMailer
  helper MarkdownHelper

  def published(notification)
    @notification = notification
    @user = notification.user
    @announcement = notification.record

    mail(
      to: @user.email,
      subject: notification.title,
      # The stream Postmark separates bulk from transactional on. An
      # announcement is the definition of broadcast, and sending it on the
      # transactional stream would put password resets behind it in the queue.
      message_stream: "broadcast"
    )
  end
end
