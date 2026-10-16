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
      ships = store.ships
      models = Model.where(slug: ships.values.pluck("slug")).index_by(&:slug)
      paths_by_slug = ships.group_by { |_path, entry| entry["slug"] }.transform_values { |pairs| pairs.map(&:first) }
      attached = {}
      unknown = []

      ships.each do |path, entry|
        slug = entry["slug"]
        model = models[slug]

        if model.nil?
          unknown << slug
          next
        end

        # Two folders claiming one model would replace each other's renders on
        # every run.
        if paths_by_slug[slug].size > 1
          log(:warn, "#{slug} is listed under #{paths_by_slug[slug].join(", ")}, skipped")
          next
        end

        next if model.ship_views_digest == entry["files"]

        fields = import(store, model, path, entry["files"])
        attached[slug] = fields if fields.any?
      rescue => e
        # Left on the old digest, so the next run tries the ship again.
        log(:error, "#{path} failed: #{e.class}: #{e.message}")
        Appsignal.report_error(e)
      end

      log(:info, "no model for #{unknown.size} ships: #{unknown.join(", ")}") if unknown.any?
      attached.each { |slug, fields| log(:info, "attached #{slug}: #{fields.join(", ")}") }
      log(:info, "attached #{attached.values.sum(&:size)} renders to #{attached.size} models")
    end

    private def import(store, model, path, digest)
      md5s = model.ship_view_md5s.dup
      files = []
      complete = true

      renders(store.listing(path), path).each do |field, name, md5|
        next if md5s[field] == md5 && model.public_send(field).attached?

        # A render already on the model, through the folder upload or an
        # earlier import that predates the stored digests.
        if current_checksum(model, field) == md5
          md5s[field] = md5
          next
        end

        begin
          file = store.fetch(path, name)
        rescue => e
          log(:warn, "#{path}/#{name} could not be fetched: #{e.class}: #{e.message}")
          complete = false
          next
        end

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

      # ActiveStorage uploads an io in `after_commit`, so the import is only
      # recorded once `save!` is back and the bytes are in storage. A render
      # that did not come down is fetched again next run.
      model.save!
      model.update_columns(ship_view_md5s: md5s, ship_views_digest: (complete ? digest : model.ship_views_digest))

      fields
    ensure
      files&.each(&:close!)
    end

    # [field, filename, md5] for every render with a field. Two names for one
    # field -- `side` from an older export beside `port` -- keep the first in
    # name order.
    private def renders(listing, path)
      claimed = listing.fetch("files", {})
        .sort_by(&:first)
        .map { |name, file| [ShipViewFields.field_for(name), name, file["md5"]] }
        .select(&:first)
        .group_by(&:first)

      claimed.map do |field, candidates|
        if candidates.size > 1
          log(:warn, "#{path}: #{candidates.map(&:second).join(", ")} all map to #{field}, took #{candidates.first.second}")
        end

        candidates.first
      end
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
