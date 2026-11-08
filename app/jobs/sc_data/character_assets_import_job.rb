# frozen_string_literal: true

module ScData
  # Attaches every file a resolved character file can name to a CharacterAsset
  # per bucket path. The export lists no MD5s for these, so the object's ETag
  # says whether it changed, and a single-part ETag, being the MD5, also
  # checks what came down.
  class CharacterAssetsImportJob < ApplicationJob
    sidekiq_options queue: "loaders"

    def perform
      return unless ::ScData::CharacterStore.configured?

      store = ::ScData::CharacterStore.new
      assets = CharacterAsset.with_attached_file.index_by(&:path)
      attached = 0
      failed = 0

      store.assets.each do |path, remote|
        asset = assets["#{PREFIX}#{path}"] || CharacterAsset.new(path: "#{PREFIX}#{path}")
        next if asset.etag == remote.etag && asset.file.attached?

        attach(store, asset, path, remote) ? attached += 1 : failed += 1
      end

      log(:info, "attached #{attached}, failed #{failed}") if attached.positive? || failed.positive?
    end

    PREFIX = "characters/"

    private def attach(store, asset, path, remote)
      file = store.fetch(File.dirname(path), File.basename(path))

      unless intact?(file, remote)
        log(:warn, "#{path} does not match its listing, skipped")
        return false
      end

      # Uploaded before it is attached, so a worker killed in between leaves
      # at most an unattached blob.
      asset.file = ActiveStorage::Blob.create_and_upload!(io: file, filename: File.basename(path))
      asset.update!(etag: remote.etag, size: remote.size)
      true
    rescue => e
      log(:warn, "#{path} could not be taken in: #{e.class}: #{e.message}")
      false
    ensure
      file&.close!
    end

    private def intact?(file, remote)
      return false if file.size != remote.size

      remote.multipart? || Digest::MD5.file(file.path).hexdigest == remote.etag
    end

    private def log(level, message)
      Rails.logger.public_send(level, "[sc_data] CharacterAssetsImportJob #{message}")
    end
  end
end
