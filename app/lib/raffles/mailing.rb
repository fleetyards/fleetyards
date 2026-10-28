# frozen_string_literal: true

module Raffles
  # What Postmark knows about the raffle mails, read from its API.
  module Mailing
    # Postmark answers a send with the message's id and the gem writes it onto
    # the mail; other delivery methods (development, test) leave none.
    def self.message_id(mail)
      mail["X-PM-Message-Id"]&.value
    end

    def self.configured?
      api_token.present?
    end

    def self.api_token
      Rails.application.credentials.postmark_api_token
    end

    # The settled state of one message from its events, or nil while Postmark
    # has nothing beyond the send itself.
    def self.status_for(message_id)
      details = Postmark::ApiClient.new(api_token).get_message(message_id)
      events = Array(details[:message_events] || details["MessageEvents"]).map { |event| (event[:type] || event["Type"]).to_s }

      return "bounced" if events.include?("Bounced")
      "delivered" if events.include?("Delivered")
    end
  end
end
