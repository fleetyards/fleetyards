# frozen_string_literal: true

require "asyncapi_helper"

# No sender exists yet: the broadcast-to-all this channel was added for is
# unbuilt, so the declaration fixes the contract before the sender is written
# rather than leaving it to be guessed from a frontend handler. There is
# nothing to assert until something broadcasts.
class NotificationsChannelTest < AsyncapiTestCase
  asyncapi_schema "cable/v1/schema"

  channel "notifications", channel_class: NotificationsChannel do
    broadcast "An announcement shown to every connected client" do
      operationId "receiveAnnouncement"
      message ::Cable::V1::Schemas::AnnouncementMessage
    end
  end
end
