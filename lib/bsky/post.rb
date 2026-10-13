# frozen_string_literal: true

require "bskyrb"
require "bsky/facets"

module Bsky
  class Post
    class Error < StandardError; end

    # What a created post is addressed by afterwards. A reply names both its
    # parent and the thread's root, so a post has to hand back enough to be
    # either.
    Record = Struct.new(:uri, :cid)

    # The preview Bluesky shows under a post. Bluesky never fetches a link's
    # page itself: a post without one is bare text, picture and all.
    LinkCard = Struct.new(:uri, :title, :description, :image, :content_type)

    # The lexicon's cap on an external embed's thumbnail.
    MAX_THUMB_BYTES = 1_000_000

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
    def create(message, root: nil, parent: nil, link_card: nil)
      record = {
        "$type" => COLLECTION,
        "createdAt" => Time.current.utc.iso8601(3),
        "text" => message
      }

      facets = ::Bsky::Facets.extract(message)
      record["facets"] = facets if facets.any?

      record["embed"] = external_embed(link_card) if link_card.present?

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

    private def external_embed(card)
      external = {
        "uri" => card.uri,
        "title" => card.title.to_s,
        "description" => card.description.to_s
      }
      thumb = upload_thumb(card)
      external["thumb"] = thumb if thumb.present?

      {"$type" => "app.bsky.embed.external", "external" => external}
    end

    # A card without its picture is still worth posting, so a thumbnail that is
    # too large or that the upload fails on is reported and left out rather
    # than failing the post.
    private def upload_thumb(card)
      return if card.image.blank?
      raise Error, "Thumbnail of #{card.image.bytesize} bytes is over Bluesky's limit" if card.image.bytesize > MAX_THUMB_BYTES

      response = HTTParty.post(
        "#{client.session.pds}/xrpc/com.atproto.repo.uploadBlob",
        body: card.image,
        headers: {
          "Authorization" => "Bearer #{client.session.access_token}",
          "Content-Type" => card.content_type
        }
      )
      blob = parse(response)&.dig("blob")

      raise Error, "Bluesky rejected the image: #{response.code} #{response.body}" if blob.blank?

      blob
    rescue Error, HTTParty::Error, Timeout::Error, SocketError, SystemCallError, OpenSSL::SSL::SSLError => e
      Appsignal.report_error(e)
      nil
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
