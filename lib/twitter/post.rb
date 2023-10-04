require "x"

module Twitter
  class Post
    attr_accessor :client

    def initialize
      credentials = {
        api_key: Rails.application.credentials.twitter_api_key,
        api_key_secret: Rails.application.credentials.twitter_api_key_secret,
        access_token: Rails.application.credentials.twitter_access_token,
        access_token_secret: Rails.application.credentials.twitter_access_token_secret
      }

      @client = X::Client.new(**credentials)
    end

    def create(message)
      client.post("tweets", "{\"text\": \"#{message}\"}")
    end
  end
end
