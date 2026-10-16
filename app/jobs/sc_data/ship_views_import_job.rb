# frozen_string_literal: true

module ScData
  # Attaches the renders sc-tools publishes to the ship-views bucket, the way the
  # admin's folder upload would: the same filename rules, and a plain save, so
  # views are cropped and holos measured by the model's own callbacks.
  #
  # Renders go live without review, so every run logs what it attached.
  class ShipViewsImportJob < ApplicationJob
    sidekiq_options queue: "loaders"

    def perform
      return unless ::ScData::ShipViewsStore.configured?

      store = ::ScData::ShipViewsStore.new
      attached = {}

      store.ships.each do |path, entry|
        model = Model.find_by(slug: entry["slug"])

        if model.nil?
          log(:warn, "no model for #{entry["slug"]} (#{path}), skipped")
          next
        end

        next if model.ship_views_digest == entry["files"]

        fields = import(store, model, path, entry["files"])
        attached[model.slug] = fields if fields.any?
      rescue => e
        # Left on the old digest, so the next run tries the ship again.
        log(:error, "#{path} failed: #{e.class}: #{e.message}")
      end

      attached.each { |slug, fields| log(:info, "attached #{slug}: #{fields.join(", ")}") }
      log(:info, "attached #{attached.values.sum(&:size)} renders to #{attached.size} models")
    end

    private def import(store, model, path, digest)
      md5s = model.ship_view_md5s.dup
      files = []
      complete = true

      renders(store.listing(path)).each do |field, name, md5|
        next if md5s[field] == md5

        # A render already on the model, through the folder upload or an
        # earlier import that predates the stored digests.
        if current_checksum(model, field) == md5
          md5s[field] = md5
          next
        end

        file = store.fetch(path, name)
        files << file

        if Digest::MD5.file(file.path).hexdigest != md5
          log(:warn, "#{path}/#{name} does not match its listed md5, skipped")
          complete = false
          next
        end

        model.public_send(:"#{field}=", {io: file, filename: name})
        md5s[field] = md5
      end

      fields = model.attachment_changes.keys

      model.ship_view_md5s = md5s
      # A render that came down wrong is fetched again next run.
      model.ship_views_digest = digest if complete
      model.save!

      fields
    ensure
      files&.each(&:close!)
    end

    # [field, filename, md5] for every render with a field. Two names for one
    # field -- `side` from an older export beside `port` -- keep the first.
    private def renders(listing)
      listing.fetch("files", {})
        .map { |name, file| [ShipViewFields.field_for(name), name, file["md5"]] }
        .select(&:first)
        .uniq(&:first)
    end

    # ActiveStorage keeps the same MD5, base64-encoded.
    private def current_checksum(model, field)
      checksum = model.public_send(field).blob&.checksum

      checksum&.unpack1("m0")&.unpack1("H*")
    end

    private def log(level, message)
      Rails.logger.public_send(level, "[sc_data] ShipViewsImportJob #{message}")
    end
  end
end
