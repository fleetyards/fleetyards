# frozen_string_literal: true

require "aws-sdk-s3"

module Overlay
  # Puts an export into the public storage bucket, under `overlay/<channel>/`,
  # where `/overlay/*` on the frontend host redirects to.
  #
  # The items file is named by its hash, so it can be cached for good; only the
  # manifest that points at it changes, and it is cached for minutes. Items
  # files the manifest no longer names are kept for a day, so a client that
  # read the previous manifest can still download what it named.
  class Publisher
    PREFIX = "overlay"

    ITEMS_CACHE_CONTROL = "public, max-age=31536000, immutable"
    MANIFEST_CACHE_CONTROL = "public, max-age=300"
    STALE_ITEMS_AFTER = 1.day

    class NotConfigured < StandardError; end

    def self.settings
      creds = Rails.application.credentials

      {
        endpoint: ::ScData::ObjectStore.storage_endpoint(creds),
        access_key_id: creds.s3_access_key,
        secret_access_key: creds.s3_secret_key,
        bucket: creds.s3_bucket
      }
    end

    def self.configured?
      settings.values.all?(&:present?)
    end

    def self.key(channel, file)
      "#{PREFIX}/#{channel}/#{file}"
    end

    # Behind the storage CDN where there is one, as ActiveStorage's redirects
    # are; otherwise straight from the bucket.
    def self.public_url(channel, file)
      cdn = Rails.configuration.app.storage_cdn_endpoint
      return "#{cdn.chomp("/")}/#{key(channel, file)}" if cdn.present?

      Aws::S3::Object.new(settings.fetch(:bucket), key(channel, file), client: new(channel).client).public_url
    end

    attr_reader :channel

    def initialize(channel, client: nil)
      @channel = channel.to_s
      @client = client
    end

    # :unchanged when the published manifest already says all of this. The same
    # bytes under a new game version only rewrite the manifest.
    def publish(result)
      published = published_manifest
      return :unchanged if published && published.except("generatedAt") == result.manifest.stringify_keys.except("generatedAt")

      if published&.dig("sha256") != result.sha256
        client.put_object(
          bucket:, key: self.class.key(channel, result.file_name), body: result.items_gzip,
          acl: "public-read", content_type: "application/gzip", cache_control: ITEMS_CACHE_CONTROL
        )
      end

      # After the items file, so the manifest never names a file that is not
      # there yet.
      client.put_object(
        bucket:, key: self.class.key(channel, "manifest.json"), body: JSON.pretty_generate(result.manifest),
        acl: "public-read", content_type: "application/json", cache_control: MANIFEST_CACHE_CONTROL
      )

      # The file the previous manifest named stays regardless of its age: a
      # client may have read that manifest moments ago.
      prune(keep: [result.file_name, published&.dig("file")].compact)

      :published
    end

    def published_manifest
      body = client.get_object(bucket:, key: self.class.key(channel, "manifest.json")).body.read
      manifest = JSON.parse(body)
      manifest if manifest.is_a?(Hash)
    rescue Aws::S3::Errors::NoSuchKey, Aws::S3::Errors::NotFound, JSON::ParserError
      nil
    end

    def client
      @client ||= begin
        raise NotConfigured, "the public storage bucket is not configured" unless self.class.configured?

        Aws::S3::Client.new(
          endpoint: settings.fetch(:endpoint),
          access_key_id: settings.fetch(:access_key_id),
          secret_access_key: settings.fetch(:secret_access_key),
          region: "unused",
          retry_limit: 5,
          retry_mode: "standard"
        )
      end
    end

    private def prune(keep:)
      cutoff = STALE_ITEMS_AFTER.ago
      kept = keep.map { |file| self.class.key(channel, file) }

      stale = client.list_objects_v2(bucket:, prefix: self.class.key(channel, "items.")).flat_map(&:contents).select do |object|
        kept.exclude?(object.key) && object.last_modified < cutoff
      end

      return if stale.empty?

      client.delete_objects(bucket:, delete: {objects: stale.map { |object| {key: object.key} }})
    end

    private def settings
      @settings ||= self.class.settings
    end

    private def bucket
      settings.fetch(:bucket)
    end
  end
end
