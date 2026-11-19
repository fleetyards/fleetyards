# frozen_string_literal: true

class FeedbackReply < ApplicationRecord
  BODY_MAX_LENGTH = Feedback::MESSAGE_MAX_LENGTH

  belongs_to :feedback, touch: true, counter_cache: :replies_count
  belongs_to :admin_user, optional: true

  validates :body, presence: true, length: {maximum: BODY_MAX_LENGTH}

  after_create_commit :notify_other_side

  private def notify_other_side
    if from_admin?
      notify_user
    else
      notify_admins
      # Reopening broadcasts the conversation itself.
      return if reopen_feedback
    end

    feedback.reload.broadcast_change
  end

  # A resolved conversation the user answers is no longer settled. Under the
  # lock the admin transitions take, so it cannot cross an admin resolving it.
  private def reopen_feedback
    feedback.with_lock { feedback.resolved? && feedback.reopen! }
  rescue => e
    Appsignal.report_error(e)
    false
  end

  private def notify_user
    user = feedback.user

    I18n.with_locale(user.notification_locale) do
      Notification.notify!(
        user:,
        type: :feedback_reply,
        title: I18n.t("notifications.feedback_reply.title"),
        body: body.truncate(200),
        link: "/settings/feedback/#{feedback.id}/",
        record: feedback
      )
    end
  rescue => e
    Appsignal.report_error(e)
  end

  private def notify_admins
    AdminNotification.notify!(
      type: :feedback,
      title: "New feedback",
      body: "#{feedback.user.username} replied: #{body.truncate(120)}",
      severity: :info,
      link: "/feedback/#{feedback.id}/",
      record: feedback,
      dedupe_key: "feedback"
    )
  rescue => e
    Appsignal.report_error(e)
  end
end
