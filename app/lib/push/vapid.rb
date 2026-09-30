# frozen_string_literal: true

module Push
  # The key pair that signs every push. Only production holds one; without it
  # nothing offers a subscription and nothing is sent.
  #
  # Never rotate it: a subscription is bound to the public key it was created
  # with, so a new pair silently ends push on every subscribed device.
  module Vapid
    def self.configured?
      public_key.present? && private_key.present? && subject.present?
    end

    def self.public_key
      credentials[:public_key]
    end

    def self.private_key
      credentials[:private_key]
    end

    def self.subject
      credentials[:subject]
    end

    def self.credentials
      Rails.application.credentials.web_push || {}
    end
  end
end
