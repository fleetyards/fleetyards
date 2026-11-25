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
  #
  # Paints only, every ship's paint maps are read again whatever its digest says,
  # and its renders are left as they are.
  #
  # Forced, every ship's listing is compared render by render, so a render
  # missing from a model whose digest is current comes down again. One
  # detached in the admin stays detached: only syncing the ship restores it.
  class ShipViewsImportJob < ApplicationJob
    include RenderImport
    include TracksRun

    sidekiq_options queue: "loaders"

    # One ship, or the paints alone, is not a run of its own worth a record.
    def perform(model_id = nil, paints_only = false, force = false, admin_user_id = nil)
      return unless ::ScData::ShipViewsStore.configured?
      return sync(model_id, paints_only, force) if model_id || paints_only

      track_run(::Imports::ScData::ShipViewsImport, admin_user_id:) { sync(nil, false, force) }
    end

    private def sync(model_id, paints_only, force)
      @restore_detached = !force || model_id.present?
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

      @progress&.step("ship_views", total: ships.size)

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

        next if model_id.nil? && !paints_only && !force && model.ship_views_digest == entry["files"]

        listing = store.listing(path)
        @liveried = Model::LIVERY_MAP_ATTACHMENT_NAMES.any? { |name| model.public_send(name).attached? }
        fields = paints_only ? [] : import(store, model, path, entry["files"], listing:)
        attached[model.slug] = fields if fields.any?

        # A paint map that did not come down is fetched again next run. A
        # liveried variant's paints come from its base ship's listing.
        if !@liveried && !textured_paints(store).call(model, path, listing.fetch("files", {}))
          model.update_columns(ship_views_digest: nil)
        end
      rescue => e
        # The renders may already have stored the new digest, so it is cleared
        # for the next run to try the ship again.
        model&.update_columns(ship_views_digest: nil)
        log(:error, "#{path} failed: #{e.class}: #{e.message}")
        Appsignal.report_error(e)
      ensure
        @progress&.advance
      end

      log(:info, "no model for #{unknown.size} ships: #{unknown.join(", ")}") if unknown.any?
      attached.each { |slug, fields| log(:info, "attached #{slug}: #{fields.join(", ")}") }
      log(:info, "attached #{attached.values.sum(&:size)} renders to #{attached.size} models")

      {attached:, unknown:}
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

    private def restore_detached? = @restore_detached

    private def textured_paints(store)
      @textured_paints ||= TexturedPaintsImport.new(store, logger: method(:log))
    end

    private def field_for(name)
      basename = name.split("/").last.to_s
      export_field = HullExport.field_for(basename)
      return export_field if export_field

      field = ShipViewFields.field_for(name)

      # A variant in its base ship's livery shows that ship's holos, which its
      # own maps are cut for; see TexturedPaintsImport.
      return if @liveried && TexturedPaintsImport::BASE_SHIP_FIELDS.include?(field&.to_sym)

      field
    end

    # Checked here rather than where it is served, so a malformed export keeps
    # the last good one instead of breaking the endpoint.
    private def render_data(field, file) = HullExport.read(field, file)

    private def render_metadata(model, field)
      model.trimmed_attachment_names.include?(field.to_s) ? {trimmed: true} : {}
    end

    private def render_md5s_column = :ship_view_md5s

    private def render_digest_column = :ship_views_digest
  end
end
