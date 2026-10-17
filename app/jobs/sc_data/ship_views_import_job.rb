# frozen_string_literal: true

module ScData
  # Attaches the renders sc-tools publishes to the ship-views bucket, the way the
  # admin's folder upload would: the same filename rules, and a plain save, so
  # views are cropped and holos measured by the model's own callbacks.
  #
  # Renders go live without review, so every run logs what it attached.
  #
  # Given a model, only that ship is synced, and its listing is compared render
  # by render even when the digest says nothing changed, so a render detached in
  # the admin comes back. A view uploaded by hand over an imported render is
  # kept: the stored md5s still name the render it replaced.
  class ShipViewsImportJob < ApplicationJob
    sidekiq_options queue: "loaders"

    def perform(model_id = nil)
      return unless ::ScData::ShipViewsStore.configured?

      store = ::ScData::ShipViewsStore.new
      ships = store.ships

      models = models_for(ships)

      if model_id
        ships = ships.select { |path, _entry| models[path]&.id == model_id }
        log(:info, "no renders listed for model #{model_id}") if ships.empty?
      end

      paths_by_model = ships.keys.group_by { |path| models[path]&.id }
      attached = {}
      unknown = []

      ships.each do |path, entry|
        model = models[path]

        if model.nil?
          unknown << entry["slug"]
          next
        end

        # Two folders claiming one model would replace each other's renders on
        # every run.
        if paths_by_model[model.id].size > 1
          log(:warn, "#{model.slug} is listed under #{paths_by_model[model.id].join(", ")}, skipped")
          next
        end

        next if model_id.nil? && model.ship_views_digest == entry["files"]

        fields = import(store, model, path, entry["files"])
        attached[model.slug] = fields if fields.any?
      rescue => e
        # Left on the old digest, so the next run tries the ship again.
        log(:error, "#{path} failed: #{e.class}: #{e.message}")
        Appsignal.report_error(e)
      end

      log(:info, "no model for #{unknown.size} ships: #{unknown.join(", ")}") if unknown.any?
      attached.each { |slug, fields| log(:info, "attached #{slug}: #{fields.join(", ")}") }
      log(:info, "attached #{attached.values.sum(&:size)} renders to #{attached.size} models")
    end

    # The path of every ship with a model. The game-file key is the stable
    # name; concepts have none, and are matched by slug. sc-tools uses the RSI
    # slug, where ours carries the manufacturer when two ships share a name
    # (`arrastra` is `rsi-arrastra`).
    private def models_for(ships)
      slugs = ships.values.pluck("slug")
      by_sc_key = unique_by(:sc_key, ships.values.pluck("scKey").compact)
      by_slug = Model.where(slug: slugs).index_by(&:slug)
      by_rsi_slug = unique_by(:rsi_slug, slugs - by_slug.keys)

      ships.to_h do |path, entry|
        [path, by_sc_key[entry["scKey"]] || by_slug[entry["slug"]] || by_rsi_slug[entry["slug"]]]
      end
    end

    # Neither column is unique, and a value two models share names neither.
    private def unique_by(column, values)
      return {} if values.empty?

      Model.where(column => values)
        .group_by(&column)
        .filter_map { |value, models| [value, models.first] if models.one? }
        .to_h
    end

    private def import(store, model, path, digest)
      md5s = model.ship_view_md5s.dup
      files = []
      complete = true

      renders(store.listing(path), path).each do |field, name, md5|
        # A render already on the model: imported before, or put there by the
        # folder upload or an import that predates the stored digests.
        if (md5s[field] == md5 || current_checksum(model, field) == md5) && stored?(model, field)
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

        # Uploaded before it is attached. Handed an io, ActiveStorage writes the
        # blob row in the save and the bytes only in an `after_commit`, so a
        # worker killed in between leaves an attachment naming a file storage
        # never received. This way a kill leaves at most an unattached blob.
        model.public_send(:"#{field}=", ActiveStorage::Blob.create_and_upload!(io: file, filename: name))
        md5s[field] = md5
      end

      fields = model.attachment_changes.keys

      # A render that did not come down is fetched again next run.
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

    # The blob row, checksum included, is written before its bytes go up, so a
    # worker killed in between leaves an attachment naming a file storage never
    # received -- and a checksum that would otherwise say it is already here.
    private def stored?(model, field)
      blob = model.public_send(field).blob

      blob.present? && blob.service.exist?(blob.key)
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
