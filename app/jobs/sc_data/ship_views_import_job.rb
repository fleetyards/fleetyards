# frozen_string_literal: true

module ScData
  # Attaches the renders sc-tools publishes to the ship-views bucket with the
  # admin's folder upload's filename rules, and a plain save, so holos are
  # measured and representations built by the model's own callbacks.
  #
  # Unlike the folder upload, views are not cropped: sc-tools already crops them
  # to the hull, and the trim would only download and decode each render to
  # find that out.
  #
  # Renders go live without review, so every run logs what it attached.
  #
  # Given a model, only that ship is synced, and its listing is compared render
  # by render even when the digest says nothing changed, so a render detached in
  # the admin comes back. A view uploaded by hand over an imported render is
  # kept: the stored md5s still name the render it replaced.
  class ShipViewsImportJob < ApplicationJob
    include RenderImport

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

    private def field_for(name)
      ShipViewFields.field_for(name)
    end

    private def render_metadata(model, field)
      model.trimmed_attachment_names.include?(field.to_s) ? {trimmed: true} : {}
    end

    private def render_md5s_column = :ship_view_md5s

    private def render_digest_column = :ship_views_digest

    private def log(level, message)
      Rails.logger.public_send(level, "[sc_data] ShipViewsImportJob #{message}")
    end
  end
end
