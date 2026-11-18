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
  #
  # Writes to every store ActiveStorage's `cloud` service writes to, so the
  # exports are wherever the uploads are while they move between providers.
  # Reads come from the first, the primary.
  class Publisher
    PREFIX = "overlay"

    ITEMS_CACHE_CONTROL = "public, max-age=31536000, immutable"
    MANIFEST_CACHE_CONTROL = "public, max-age=300"
    STALE_ITEMS_AFTER = 1.day

    SETTING_KEYS = %i[endpoint access_key_id secret_access_key bucket region].freeze

    class NotConfigured < StandardError; end

    Store = Data.define(:client, :bucket)

    # One settings hash per store, primary first, as `config/storage.yml`
    # defines `cloud`: a mirror's primary and mirrors, or the service itself.
    def self.settings
      # Loading the Blob class is what reads config/storage.yml into
      # service_configurations.
      ActiveStorage::Blob.services
      configs = Rails.configuration.active_storage.service_configurations.to_h.with_indifferent_access
      cloud = configs.fetch(:cloud, {})
      names = (cloud[:service] == "Mirror") ? [cloud[:primary], *cloud[:mirrors]] : [:cloud]

      names.map { |name| configs.fetch(name, {}).slice(*SETTING_KEYS).symbolize_keys }
    end

    def self.configured?(settings = self.settings)
      settings.any? && settings.all? { |store| SETTING_KEYS.all? { |key| store[key].present? } }
    end

    def self.key(channel, file)
      "#{PREFIX}/#{channel}/#{file}"
    end

    # Behind the storage CDN where there is one, as ActiveStorage's redirects
    # are; otherwise straight from the primary's bucket.
    def self.public_url(channel, file)
      cdn = Rails.configuration.app.storage_cdn_endpoint
      return "#{cdn.chomp("/")}/#{key(channel, file)}" if cdn.present?

      primary = new(channel).stores.first
      Aws::S3::Object.new(primary.bucket, key(channel, file), client: primary.client).public_url
    end

    attr_reader :channel

    def initialize(channel, stores: nil)
      @channel = channel.to_s
      @stores = stores
    end

    # :unchanged when the published manifest already says all of this. The same
    # bytes under a new game version only rewrite the manifest.
    def publish(result)
      published = published_manifest
      return :unchanged if published && published.except("generatedAt") == result.manifest.stringify_keys.except("generatedAt")

      stores.each do |store|
        if published&.dig("sha256") != result.sha256
          store.client.put_object(
            bucket: store.bucket, key: self.class.key(channel, result.file_name), body: result.items_gzip,
            acl: "public-read", content_type: "application/gzip", cache_control: ITEMS_CACHE_CONTROL
          )
        end

        # After the items file, so the manifest never names a file that is not
        # there yet.
        store.client.put_object(
          bucket: store.bucket, key: self.class.key(channel, "manifest.json"), body: JSON.pretty_generate(result.manifest),
          acl: "public-read", content_type: "application/json", cache_control: MANIFEST_CACHE_CONTROL
        )

        # The file the previous manifest named stays regardless of its age: a
        # client may have read that manifest moments ago.
        prune(store, keep: [result.file_name, published&.dig("file")].compact)
      end

      :published
    end

    def published_manifest
      primary = stores.first
      body = primary.client.get_object(bucket: primary.bucket, key: self.class.key(channel, "manifest.json")).body.read
      manifest = JSON.parse(body)
      manifest if manifest.is_a?(Hash)
    rescue Aws::S3::Errors::NoSuchKey, Aws::S3::Errors::NotFound, JSON::ParserError
      nil
    end

    def stores
      @stores ||= begin
        settings = self.class.settings
        raise NotConfigured, "the public storage bucket is not configured" unless self.class.configured?(settings)

        settings.map do |store|
          client = Aws::S3::Client.new(
            endpoint: store.fetch(:endpoint),
            access_key_id: store.fetch(:access_key_id),
            secret_access_key: store.fetch(:secret_access_key),
            region: store.fetch(:region),
            retry_limit: 5,
            retry_mode: "standard"
          )
          Store.new(client:, bucket: store.fetch(:bucket))
        end
      end
    end

    private def prune(store, keep:)
      cutoff = STALE_ITEMS_AFTER.ago
      kept = keep.map { |file| self.class.key(channel, file) }

      listing = store.client.list_objects_v2(bucket: store.bucket, prefix: self.class.key(channel, "items."))
      stale = listing.flat_map(&:contents).select do |object|
        kept.exclude?(object.key) && object.last_modified < cutoff
      end

      return if stale.empty?

      store.client.delete_objects(bucket: store.bucket, delete: {objects: stale.map { |object| {key: object.key} }})
    end
  end
end
