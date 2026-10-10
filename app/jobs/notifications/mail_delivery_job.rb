# frozen_string_literal: true

module Notifications
  # A notification can be deleted while its mail still waits in the queue, for
  # example when the fleet announcement it was about is taken down. There is
  # nothing left to send then, and retrying cannot bring it back.
  class MailDeliveryJob < ActionMailer::MailDeliveryJob
    discard_on ActiveJob::DeserializationError
  end
end
