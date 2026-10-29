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

    # Where on the flight holo hull each item port sits. Only the flying pose
    # is exported without its components, so there is no landed set.
    HARDPOINT_TRANSFORMS_NAME = /\A(?:flight[-_ ]?)?hardpoints\.json\z/i

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

        listing = store.listing(path)
        @liveried = model.holo_texture.attached?
        fields = import(store, model, path, entry["files"], listing:)
        attached[model.slug] = fields if fields.any?

        # A paint map that did not come down is fetched again next run. A
        # liveried variant's paints come from its base ship's listing.
        if !@liveried && !textured_paints(store).call(model, path, listing.fetch("files", {}))
          model.update_columns(ship_views_digest: nil)
        end
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

    private def textured_paints(store)
      @textured_paints ||= TexturedPaintsImport.new(store, logger: method(:log))
    end

    private def field_for(name)
      return "hardpoint_transforms" if HARDPOINT_TRANSFORMS_NAME.match?(name.split("/").last.to_s)

      field = ShipViewFields.field_for(name)

      # A variant in its base ship's livery shows that ship's holos, which its
      # own maps are cut for; see TexturedPaintsImport.
      return if @liveried && TexturedPaintsImport::BASE_SHIP_FIELDS.include?(field&.to_sym)

      field
    end

    # Checked here rather than where it is served, so a malformed export keeps
    # the last good one instead of breaking the endpoint.
    private def render_data(_field, file)
      transforms = JSON.parse(file.read)

      raise ArgumentError, "no ports listed" unless transforms.is_a?(Hash) && transforms["ports"].is_a?(Array)

      transforms["ports"].each_with_index do |port, index|
        raise ArgumentError, "port #{index} is malformed" unless valid_port?(port)
      end

      transforms
    end

    private def valid_port?(port)
      port.is_a?(Hash) &&
        port["name"].is_a?(String) &&
        numbers?(port["position"], 3) &&
        numbers?(port["rotation"], 4) &&
        (port["parent"].nil? || port["parent"].is_a?(String)) &&
        (port["defaultItem"].nil? || port["defaultItem"].is_a?(String)) &&
        Array(port["types"]).all? { |type| type.is_a?(Hash) && type["type"].is_a?(String) }
    end

    private def numbers?(value, size)
      value.is_a?(Array) && value.size == size && value.all?(Numeric)
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
