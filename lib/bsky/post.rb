# frozen_string_literal: true

require "bskyrb"

module Bsky
  class Post
    class Error < StandardError; end

    # What a created post is addressed by afterwards. A reply names both its
    # parent and the thread's root, so a post has to hand back enough to be
    # either.
    Record = Struct.new(:uri, :cid)

    # Bluesky counts graphemes, not bytes, and caps a post at 300.
    MAX_LENGTH = 300

    COLLECTION = "app.bsky.feed.post"

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

    # Builds the record here rather than through bskyrb's `create_post_or_reply`,
    # which sets `root` and `parent` to the same post. That is right for the
    # second post in a thread and wrong for every one after it: the third would
    # claim the second as the root, and Bluesky would render two threads of two
    # rather than one of three.
    def create(message, root: nil, parent: nil)
      record = {
        "$type" => COLLECTION,
        "createdAt" => Time.current.utc.iso8601(3),
        "text" => message
      }

      if parent.present?
        record["reply"] = {
          "root" => ref(root || parent),
          "parent" => ref(parent)
        }
      end

      created(client.create_record({
        "collection" => COLLECTION,
        "repo" => client.session.did,
        "record" => record
      }))
    end

    private def ref(post)
      {"uri" => post.uri, "cid" => post.cid}
    end

    private def created(response)
      body = parse(response)

      raise Error, "Bluesky rejected the post: #{response.code} #{response.body}" unless body.is_a?(Hash) && body["uri"].present?

      Record.new(body["uri"], body["cid"])
    end

    private def parse(response)
      JSON.parse(response.body.to_s)
    rescue JSON::ParserError
      nil
    end
  end
end
