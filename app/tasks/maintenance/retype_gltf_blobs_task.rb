# frozen_string_literal: true

module Maintenance
  # Restamps the glTF holos the sc_data imports stored as
  # application/octet-stream with their own type, now that Marcel knows it
  # (config/initializers/active_storage.rb).
  #
  # The bucket serves each object under the Content-Type it was uploaded with,
  # and the CDN only compresses model/gltf-binary, so the type is rewritten on
  # every store the blob lives on -- by copying each object onto itself with
  # its other headers kept -- and only then on the blob.
  #
  # The CDN caches objects for months: purge the pull zone after a real run, or
  # the old type is served until the cache expires.
  class RetypeGltfBlobsTask < MaintenanceTasks::Task
    UNTYPED = ["application/octet-stream", "", nil].freeze

    # Reports what it would change unless turned off.
    attribute :dry_run, :boolean, default: true
    # A few blobs to try a real run on first, comma-separated; all when blank.
    attribute :blob_ids, :string

    def collection
      blobs = ActiveStorage::Blob
        .where(content_type: UNTYPED)
        .where("filename ILIKE '%.glb' OR filename ILIKE '%.gltf'")
      ids = blob_ids.to_s.split(",").map(&:strip).compact_blank
      ids.any? ? blobs.where(id: ids) : blobs
    end

    def count
      collection.count
    end

    def process(blob)
      content_type = Marcel::MimeType.for(name: blob.filename.to_s)

      if dry_run
        puts "would retype Blob##{blob.id} #{blob.filename} (#{blob.key}) to #{content_type}"
        return
      end

      s3_services(blob.service).each { |service| retype_object(service, blob.key, content_type) }
      blob.update!(content_type:)
      puts "retyped Blob##{blob.id} #{blob.filename} (#{blob.key}) to #{content_type}"
    end

    private def s3_services(service)
      services = service.respond_to?(:mirrors) ? [service.primary, *service.mirrors] : [service]
      services.select { |candidate| candidate.respond_to?(:bucket) }
    end

    private def retype_object(service, key, content_type)
      object = service.bucket.object(key).load

      object.copy_from(
        object,
        metadata_directive: "REPLACE",
        content_type:,
        content_disposition: object.content_disposition,
        cache_control: object.cache_control,
        metadata: object.metadata,
        **service.upload_options.slice(:acl)
      )

      served = service.bucket.object(key).content_type
      return if served == content_type

      raise "#{service.name}: #{key} is still served as #{served.inspect} after the copy"
    end
  end
end
