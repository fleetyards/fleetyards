# frozen_string_literal: true

module ScData
  # The maps a ship's textured holo can be repainted with: per paint a base
  # colour and an occlusion/roughness/metallic WebP beside `flight_textured.glb`,
  # listed in `flight_textured.json` under the palette's slug. Each lands on the
  # ship's paints that the palette stands for.
  #
  # The lite export has a smaller atlas, so `flight_textured_lite.json` lists
  # maps of its own. Either set paints its variant's landed holo too: both
  # states share the one atlas.
  #
  # A palette names no paint of ours. It reaches one through the game's paint
  # item -- listed with the palette, or else carrying the palette's name -- and
  # the paint that item is linked to. That link is made once per paint name, on
  # the base ship, so the variants' paints are found by the same name.
  #
  # A palette no paint stands for may be a variant's own colours: the Gladius
  # Valiant is the Gladius in `paint_gladius_valiant`, the item in its paint
  # slot. That variant takes the base ship's textured holos and hull, and the
  # maps as its own -- and its paints are repainted from the base ship's
  # listing too, since its holos are the base ship's.
  class TexturedPaintsImport
    # Listing => {attachment => the manifest key naming its file}. Only the base
    # colour, listed first, is required: without it a paint has nothing to show.
    LISTINGS = {
      "flight_textured.json" => {holo_texture: "base", holo_texture_orm: "orm"},
      "flight_textured_lite.json" => {holo_texture_lite: "base", holo_texture_orm_lite: "orm"}
    }.freeze

    # Listing => the holos its maps fit.
    HOLOS = {
      "flight_textured.json" => %i[holo_textured landed_holo_textured],
      "flight_textured_lite.json" => %i[holo_textured_lite landed_holo_textured_lite]
    }.freeze

    # What a liveried variant takes from its base ship rather than its own
    # export: the loadout preview mounts its parts on the base ship's hull.
    BASE_SHIP_FIELDS = (HOLOS.values.flatten + %i[holo_hull]).freeze

    def initialize(store, logger:)
      @store = store
      @logger = logger
    end

    # False when a map did not come down, so the caller retries the ship.
    def call(model, path, files)
      LISTINGS.map { |name, fields| import(model, path, files, name, fields) }.all?
    end

    private def import(model, path, files, name, fields)
      return true unless files.key?(name)

      listing = fetch_listing(path, name)
      return false if listing.nil?

      complete = true
      palettes = listing.fetch("paints", {})
      own = palettes.transform_values { |entry| paints_for(model, entry) }
      liveried = liveried_variants(model, palettes.filter_map { |slug, entry| entry if own[slug].empty? })

      palettes.each do |slug, entry|
        maps = maps_for(entry, files, fields)

        unless maps.key?(fields.keys.first)
          @logger.call(:warn, "#{path}/#{name}: paint #{slug} names no listed map")
          next
        end

        records = own[slug] + liveried.flat_map { |variant| paints_for(variant, entry) }

        if records.empty?
          records = liveried_variants(model, [entry])

          if records.empty?
            @logger.call(:info, "#{path}/#{name}: paint #{slug} matches no paint of #{model.slug}")
            next
          end

          share_holos(model, records, HOLOS.fetch(name))
          share_hull(model, records)
        end

        maps.each do |field, (file_name, md5)|
          stale = records.reject { |record| current?(record.public_send(field), md5) }
          next if stale.empty?

          complete &= attach(stale, field, path, file_name, md5)
        end
      end

      complete
    end

    private def fetch_listing(path, name)
      file = @store.fetch(path, name)
      JSON.parse(file.read)
    rescue => e
      @logger.call(:warn, "#{path}/#{name} could not be read: #{e.class}: #{e.message}")
      nil
    ensure
      file&.close!
    end

    # Attachment => [file name, md5], for the maps the listing has.
    private def maps_for(entry, files, fields)
      fields.each_with_object({}) do |(field, key), maps|
        name = entry[key]
        md5 = files.dig(name, "md5") if name.present?
        maps[field] = [name, md5] if md5
      end
    end

    private def attach(records, field, path, name, md5)
      file = @store.fetch(path, name)

      if Digest::MD5.file(file.path).hexdigest != md5
        @logger.call(:warn, "#{path}/#{name} does not match its listed md5, skipped")
        return false
      end

      # One upload shared by every paint the palette stands for.
      blob = ActiveStorage::Blob.create_and_upload!(io: file, filename: name)
      records.each { |record| record.update!(field => blob) }

      true
    rescue => e
      @logger.call(:warn, "#{path}/#{name} could not be fetched: #{e.class}: #{e.message}")
      false
    ensure
      file&.close!
    end

    private def paints_for(model, entry)
      components = paint_components(entry)
      return [] if components.empty?

      linked = ModelPaint.where(component_id: components.map(&:id))
      names = linked.pluck(:name).map { |paint_name| PaintComponentMatcher.normalize(paint_name) }

      model.paints.to_a.select do |paint|
        components.any? { |component| component.id == paint.component_id } ||
          names.include?(PaintComponentMatcher.normalize(paint.name))
      end
    end

    private def liveried_variants(model, entries)
      items = entries.flat_map { |entry| Array(entry["items"]) }.select(&:present?)
      return [] if items.empty?

      liveried = Hardpoint.paints_category
        .where(parent_type: "Model")
        .joins(:component)
        .where(components: {sc_key: items})
        .select(:parent_id)

      model.variants.where(id: liveried).to_a
    end

    # The base ship's blobs, shared rather than copied.
    private def share_holos(model, variants, fields)
      fields.each do |field|
        blob = model.public_send(field).blob
        next if blob.nil?

        variants.each do |variant|
          variant.update!(field => blob) unless variant.public_send(field).blob == blob
        end
      end
    end

    # The hull-level ports sit where the base ship's do, so a variant's own
    # transforms win where it has them: below a stock part they are that part's
    # ports, and the Gladius Pirate's racks carry more missiles.
    private def share_hull(model, variants)
      share_holos(model, variants, %i[holo_hull])

      return if model.hardpoint_transforms.nil?

      variants.each do |variant|
        variant.update!(hardpoint_transforms: model.hardpoint_transforms) if variant.hardpoint_transforms.nil?
      end
    end

    private def paint_components(entry)
      scope = Component.where(category: "paints")
      items = Array(entry["items"]).select(&:present?)

      if items.any?
        scope.where(sc_key: items).to_a
      elsif entry["name"].present?
        scope.where(name: entry["name"]).to_a
      else
        []
      end
    end

    # The blob row is written before its bytes go up; see RenderImport#stored?.
    private def current?(attachment, md5)
      blob = attachment.blob
      return false if blob.nil?

      blob.checksum.unpack1("m0").unpack1("H*") == md5 && blob.service.exist?(blob.key)
    end
  end
end
