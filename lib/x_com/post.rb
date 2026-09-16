# frozen_string_literal: true

require "faraday"
require "openssl"
require "base64"
require "securerandom"

module XCom
  # Posts to X.com via the v2 API.
  #
  # OAuth 1.0a rather than OAuth 2.0 user-context, which is the other way v2
  # accepts a write: OAuth 2.0 would mean storing and refreshing a token whose
  # lifetime is two hours, for what is one service account posting a handful of
  # times a month. 1.0a signs each request from four static secrets and has no
  # lifecycle at all.
  #
  # Named XCom rather than X so the constant is not a single letter at the top
  # of the global namespace.
  class Post
    ENDPOINT = "https://api.twitter.com/2/tweets"

    MAX_LENGTH = 280

    # X bills every URL at 23 characters whatever its real length, because it
    # wraps them through t.co. A post that reads as over the limit in plain
    # characters can therefore be fine, which is why the copy in
    # docs/announcements carries two different counts for the same text.
    URL_WEIGHT = 23
    URL_PATTERN = %r{https?://\S+}

    def self.weighted_length(text)
      text.to_s.gsub(URL_PATTERN) { "x" * URL_WEIGHT }.length
    end

    class Error < StandardError
      attr_reader :status, :body

      def initialize(status, body)
        @status = status
        @body = body
        super("X API error #{status}: #{body}")
      end
    end

    def self.api_key = Rails.application.credentials.x_api_key

    def self.api_secret = Rails.application.credentials.x_api_secret

    def self.access_token = Rails.application.credentials.x_access_token

    def self.access_token_secret = Rails.application.credentials.x_access_token_secret

    def self.configured?
      [api_key, api_secret, access_token, access_token_secret].all?(&:present?)
    end

    # Returns the id of the created post. `reply_to` makes it a reply, which is
    # all a thread is on X: every post after the first names the one before it.
    def create(message, reply_to: nil)
      raise Error.new(0, "missing credentials") unless self.class.configured?

      payload = {text: message}
      payload[:reply] = {in_reply_to_tweet_id: reply_to} if reply_to.present?
      body = payload.to_json
      response = connection.post(ENDPOINT) do |request|
        request.headers["Authorization"] = authorization_header
        request.headers["Content-Type"] = "application/json"
        request.body = body
      end

      handle(response)
    end

    private def handle(response)
      raise Error.new(response.status, response.body) unless response.status.between?(200, 299)

      parsed = JSON.parse(response.body.to_s)
      id = parsed.dig("data", "id")

      raise Error.new(response.status, response.body) if id.blank?

      id
    rescue JSON::ParserError
      raise Error.new(response.status, response.body)
    end

    # The request body is JSON, so it contributes nothing to the signature --
    # OAuth 1.0a only folds in form-encoded parameters, and there are none here.
    private def authorization_header
      params = {
        "oauth_consumer_key" => self.class.api_key,
        "oauth_nonce" => SecureRandom.hex(16),
        "oauth_signature_method" => "HMAC-SHA1",
        "oauth_timestamp" => Time.current.to_i.to_s,
        "oauth_token" => self.class.access_token,
        "oauth_version" => "1.0"
      }

      params["oauth_signature"] = signature(params)

      "OAuth " + params.sort.map { |key, value| "#{escape(key)}=\"#{escape(value)}\"" }.join(", ")
    end

    private def signature(params)
      base = [
        "POST",
        escape(ENDPOINT),
        escape(params.sort.map { |key, value| "#{escape(key)}=#{escape(value)}" }.join("&"))
      ].join("&")

      key = "#{escape(self.class.api_secret)}&#{escape(self.class.access_token_secret)}"

      Base64.strict_encode64(OpenSSL::HMAC.digest("SHA1", key, base))
    end

    # RFC 3986, which is stricter than CGI.escape: a space is %20 and the four
    # unreserved marks are left alone. A signature built with CGI.escape
    # verifies against nothing.
    private def escape(value)
      CGI.escape(value.to_s).gsub("+", "%20").gsub("%7E", "~")
    end

    # Seconds. An unbounded request holds a Sidekiq worker for as long as X
    # feels like taking.
    TIMEOUT = 10
    OPEN_TIMEOUT = 5

    # No retry middleware, deliberately. Creating a post is not idempotent, and
    # the OAuth header is signed once before the request is handed over -- so a
    # replay carries a spent nonce and, worse, can publish a second copy of an
    # announcement whose first attempt landed behind an ambiguous 5xx. A failed
    # delivery is retried from the admin, where a human can see whether the
    # first one arrived.
    private def connection
      @connection ||= Faraday.new(request: {timeout: TIMEOUT, open_timeout: OPEN_TIMEOUT}) do |c|
        c.headers["User-Agent"] = "Fleetyards (https://fleetyards.net, 1.0)"
      end
    end
  end
end
