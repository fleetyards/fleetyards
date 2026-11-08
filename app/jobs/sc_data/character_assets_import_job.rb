# frozen_string_literal: true

module ScData
  # Attaches every file a resolved character file can name to a CharacterAsset
  # per bucket path. The export lists no MD5s for these, so the object's ETag
  # says whether it changed, and a single-part ETag, being the MD5, also
  # checks what came down.
  #
  # Then copies what the catalogue says each hat, helmet, mask and hood does
  # to the hair onto the equipment it names, including equipment imported
  # since the catalogue last changed.
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

      apply_head_wear
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

    FITS = %w[rigid face_wrap].freeze

    private def apply_head_wear
      catalog = CharacterAsset.joins(:file_attachment).find_by(path: ::Chf::Context::CATALOG)
      return if catalog.nil?

      items = JSON.parse(catalog.file.download).fetch("headwear_items", {})
      changed = 0

      Equipment.where.not(sc_key: nil).or(Equipment.where.not(head_wear: nil)).select(:id, :sc_key, :head_wear).find_each do |equipment|
        head_wear = head_wear(items[equipment.sc_key.to_s.downcase])
        next if equipment.head_wear == head_wear

        # Touched, as the equipment payload is cached by the row's timestamp.
        equipment.update_columns(head_wear:, updated_at: Time.current)
        changed += 1
      end

      log(:info, "head wear changed on #{changed} items") if changed.positive?
    rescue JSON::ParserError => e
      log(:warn, "catalogue could not be read: #{e.message}")
    end

    # Kept whole, with every field the payload promises.
    private def head_wear(item)
      return unless item.is_a?(Hash) && item["type"].is_a?(String)

      {
        "type" => item["type"],
        "fit" => FITS.include?(item["fit"]) ? item["fit"] : "rigid",
        "hairTag" => (item["hairTag"] if item["hairTag"].is_a?(String)),
        "maskFacialHair" => item["maskFacialHair"] == true,
        "addsTags" => Array(item["addsTags"]).grep(String),
        "hiddenParts" => Array(item["hiddenParts"]).grep(String)
      }
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
