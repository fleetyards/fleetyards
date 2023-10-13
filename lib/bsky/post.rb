require "bskyrb"

module Bsky
  class Post
    attr_accessor :client

    def initialize
      username = Rails.application.credentials.bsky_handle
      password = Rails.application.credentials.bsky_app_password
      pds_url = Rails.application.credentials.bsky_endpoint

      credentials = Bskyrb::Credentials.new(username, password)
      session = Bskyrb::Session.new(credentials, pds_url)
      @client = Bskyrb::RecordManager.new(session)
    end

    def create(message)
      client.create_post(message)
    end
  end
end
