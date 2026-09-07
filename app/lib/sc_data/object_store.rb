# frozen_string_literal: true

require "aws-sdk-s3"

module ScData
  # What the sc_data stores have in common: where the bucket is, how to reach
  # it, and how to move tens of thousands of small objects between it and a
  # local tree without waiting out one round trip at a time.
  #
  # A subclass says which prefix it covers and where that tree lives on disk.
  # `ParsedStore` mirrors the parsed tree in both directions; `RawStore` only
  # ever fetches an export.
  class ObjectStore
    # Both trees are mostly small objects, so the wall clock is round-trip bound
    # rather than bandwidth bound. Kept modest to stay well inside provider rate
    # limits on the loaders container.
    CONCURRENCY = 16

    class NotConfigured < StandardError; end

    class MissingTree < StandardError; end

    # One object as a listing describes it.
    #
    # `etag` is the content MD5 only for a single-part upload. A multipart one is
    # a digest of the part digests with the part count appended, which no local
    # file can reproduce -- so anything comparing digests has to ask first.
    RemoteObject = Struct.new(:etag, :size) do
      def multipart?
        etag.include?("-")
      end
    end

    # The sc_data buckets sit on the same account and endpoint as
    # ActiveStorage's, and object-storage keys here are project-scoped, so the
    # pair already deployed for `config/storage.yml` reaches them too.
    #
    # Everything but the bucket therefore falls back to that existing config, so
    # the only value production carries for this is the one that actually
    # differs. Each `sc_data_s3` key stays an override, for a separate account
    # later or for running the CLI outside 1Password.
    def self.settings
      creds = Rails.application.credentials

      {
        endpoint: Rails.app.creds.option(:sc_data_s3, :endpoint) || storage_endpoint(creds),
        access_key_id: Rails.app.creds.option(:sc_data_s3, :access_key_id) || creds.s3_access_key,
        secret_access_key: Rails.app.creds.option(:sc_data_s3, :secret_access_key) || creds.s3_secret_key,
        bucket: Rails.app.creds.option(:sc_data_s3, :bucket)
      }
    end

    # `config/storage.yml` stores the scheme apart from the host, so it has to be
    # rejoined here. Nil rather than a bare "://" when either half is missing, so
    # `configured?` reports it as absent instead of building a broken client.
    def self.storage_endpoint(creds)
      return if creds.s3_protocol.blank? || creds.s3_endpoint.blank?

      "#{creds.s3_protocol}://#{creds.s3_endpoint}"
    end

    def self.configured?(settings = self.settings)
      settings.values.all?(&:present?)
    end

    def initialize(client: nil, settings: nil)
      @client = client
      @provided_settings = settings
    end

    # Where this store's tree lives on disk.
    def local_root
      raise NotImplementedError
    end

    # The key prefix this store covers, without a trailing slash.
    private def prefix
      raise NotImplementedError
    end

    private def key_for(path)
      "#{prefix}/#{path}"
    end

    private def local_path(path)
      File.join(local_root, path)
    end

    # Relative path => RemoteObject for everything under the prefix.
    private def remote_objects
      objects = {}

      client.list_objects_v2(bucket:, prefix: "#{prefix}/").each do |page|
        page.contents.each do |object|
          objects[object.key.delete_prefix("#{prefix}/")] =
            RemoteObject.new(object.etag.delete('"'), object.size)
        end
      end

      objects
    end

    private def download(path)
      target = local_path(path)
      FileUtils.mkdir_p(File.dirname(target))

      client.get_object(bucket:, key: key_for(path), response_target: target)
    end

    private def each_in_parallel(paths)
      return 0 if paths.empty?

      queue = Queue.new
      paths.each { |path| queue << path }
      queue.close # so a drained `pop` returns nil instead of blocking forever

      errors = Queue.new

      Array.new([CONCURRENCY, paths.size].min) do
        Thread.new do
          while (path = queue.pop)
            begin
              yield path
            rescue => e
              errors << "#{path}: #{e.message}"
            end
          end
        end
      end.each(&:join)

      raise errors.pop unless errors.empty?

      paths.size
    end

    private def bucket
      settings.fetch(:bucket)
    end

    private def settings
      @settings ||= begin
        settings = @provided_settings || self.class.settings

        unless self.class.configured?(settings)
          missing = settings.select { |_, value| value.blank? }.keys

          raise NotConfigured, "missing sc_data_s3 settings: #{missing.join(", ")}"
        end

        settings
      end
    end

    private def client
      @client ||= Aws::S3::Client.new(
        endpoint: settings.fetch(:endpoint),
        access_key_id: settings.fetch(:access_key_id),
        secret_access_key: settings.fetch(:secret_access_key),
        region: "unused"
      )
    end
  end
end
