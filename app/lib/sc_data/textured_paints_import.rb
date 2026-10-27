# frozen_string_literal: true

module ScData
  # The base-colour maps a ship's textured holo can be repainted with: one WebP
  # per paint beside `flight_textured.glb`, listed in `flight_textured.json`
  # under the palette's slug. Each lands on the ship's paints that the palette
  # stands for.
  #
  # A palette names no paint of ours. It reaches one through the game's paint
  # item -- listed with the palette, or else carrying the palette's name -- and
  # the paint that item is linked to. That link is made once per paint name, on
  # the base ship, so the variants' paints are found by the same name.
  class TexturedPaintsImport
    LISTING = "flight_textured.json"

    def initialize(store, logger:)
      @store = store
      @logger = logger
    end

    # False when a map did not come down, so the caller retries the ship.
    def call(model, path, files)
      return true unless files.key?(LISTING)

      listing = fetch_listing(path)
      return false if listing.nil?

      complete = true

      listing.fetch("paints", {}).each do |slug, entry|
        name = entry["base"]
        md5 = files.dig(name, "md5")

        if name.blank? || md5.nil?
          @logger.call(:warn, "#{path}: paint #{slug} names no listed map")
          next
        end

        paints = paints_for(model, entry)

        if paints.empty?
          @logger.call(:info, "#{path}: paint #{slug} matches no paint of #{model.slug}")
          next
        end

        stale = paints.reject { |paint| current?(paint, md5) }
        next if stale.empty?

        complete &= attach(stale, path, name, md5)
      end

      complete
    end

    private def fetch_listing(path)
      file = @store.fetch(path, LISTING)
      JSON.parse(file.read)
    rescue => e
      @logger.call(:warn, "#{path}/#{LISTING} could not be read: #{e.class}: #{e.message}")
      nil
    ensure
      file&.close!
    end

    private def attach(paints, path, name, md5)
      file = @store.fetch(path, name)

      if Digest::MD5.file(file.path).hexdigest != md5
        @logger.call(:warn, "#{path}/#{name} does not match its listed md5, skipped")
        return false
      end

      # One upload shared by every paint the palette stands for.
      blob = ActiveStorage::Blob.create_and_upload!(io: file, filename: name)
      paints.each { |paint| paint.update!(holo_texture: blob) }

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
    private def current?(paint, md5)
      blob = paint.holo_texture.blob
      return false if blob.nil?

      blob.checksum.unpack1("m0").unpack1("H*") == md5 && blob.service.exist?(blob.key)
    end
  end
end
