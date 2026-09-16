# frozen_string_literal: true

require "bskyrb"

module Bsky
  class Post
    class Error < StandardError; end

    # Bluesky counts graphemes, not bytes, and caps a post at 300.
    MAX_LENGTH = 300

    def self.handle = Rails.application.credentials.bsky_handle

    def self.app_password = Rails.application.credentials.bsky_app_password

    def self.endpoint = Rails.application.credentials.bsky_endpoint

    def self.configured?
      handle.present? && app_password.present? && endpoint.present?
    end

    # The session is opened on first use rather than in the constructor: an
    # install with no Bluesky credentials would otherwise raise merely by
    # naming this class, which is what a `configured?` check is meant to avoid.
    def client
      @client ||= begin
        credentials = Bskyrb::Credentials.new(self.class.handle, self.class.app_password)
        session = Bskyrb::Session.new(credentials, self.class.endpoint)
        Bskyrb::RecordManager.new(session)
      end
    end

    # Returns the AT URI of the created post, which is what links back to it.
    def create(message)
      response = client.create_post(message)
      body = parse(response)

      raise Error, "Bluesky rejected the post: #{response.code} #{response.body}" unless body.is_a?(Hash) && body["uri"].present?

      body["uri"]
    end

    private def parse(response)
      JSON.parse(response.body.to_s)
    rescue JSON::ParserError
      nil
    end
  end
end
