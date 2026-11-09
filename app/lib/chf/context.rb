# frozen_string_literal: true

module Chf
  # What a character file is resolved against: the imported customizer
  # catalogue, each body's face library header and the tone its textured holo
  # is baked at. `digest` changes whenever any of it does, so a stored
  # resolution knows when it is stale.
  #
  # The catalogue is a 2 MB file, parsed once per process per version.
  class Context
    CATALOG = "characters/chf/catalog.json"

    @cache = {}
    @lock = Mutex.new

    class << self
      # Nil until the catalogue and at least one face library are imported.
      def current
        asset = CharacterAsset.joins(:file_attachment).with_attached_file.find_by(path: CATALOG)
        bodies = CharacterBody.with_attached_face_index.with_attached_face_positions.with_attached_face_normals
          .where.not(face_library: nil).select(&:face_library?)
        return if asset.nil? || bodies.empty?

        new(asset, bodies)
      end

      # Only the newest version of each file stays parsed: an older one is
      # replaced, not kept beside it. Parsed outside the lock, so one slow
      # parse does not hold up every other request.
      def parsed(kind, version)
        cached = @lock.synchronize { @cache[kind] }
        return cached.last if cached&.first == version

        value = yield
        @lock.synchronize { @cache[kind] = [version, value] }
        value
      end

      def reset!
        @lock.synchronize { @cache.clear }
      end
    end

    def initialize(asset, bodies)
      @asset = asset
      @bodies = bodies
    end

    def catalog
      self.class.parsed(:catalog, @asset.etag) { JSON.parse(@asset.file.download) }
    end

    def libraries
      @bodies.to_h { |body| [body.key, self.class.parsed([:library, body.key], body.face_index.checksum) { JSON.parse(body.face_index.download) }] }
    end

    def body?(key) = @bodies.any? { |body| body.key == key }

    def skin_tones = @bodies.to_h { |body| [body.key, body.skin_tone] }

    def digest
      @digest ||= Digest::MD5.hexdigest(
        [Resolver::VERSION, @asset.etag, @bodies.map { |body| [body.key, body.face_index.checksum, body.skin_tone] }.sort].to_json
      )
    end

    def resolve(chf, worn: [])
      Resolver.new(chf, catalog:, libraries:, skin_tones:, worn:).spec
    end

    # The spec with every bucket path a viewer loads replaced by the URL it is
    # served from, or nil while that file is not imported.
    def served(spec)
      paths = []
      collect(spec, paths)
      urls = CharacterAsset.where(path: paths.uniq).joins(:file_attachment).with_attached_file.to_h do |asset|
        [asset.path, Rails.application.routes.url_helpers.rails_blob_url(asset.file)]
      end

      rewrite(spec.except("assets"), urls)
    end

    private def collect(value, paths)
      case value
      when Hash then value.each_value { |v| collect(v, paths) }
      when Array then value.each { |v| collect(v, paths) }
      when String then paths << value if value.start_with?("characters/")
      end
    end

    private def rewrite(value, urls)
      case value
      when Hash then value.transform_values { |v| rewrite(v, urls) }
      when Array then value.map { |v| rewrite(v, urls) }
      when String then value.start_with?("characters/") ? urls[value] : value
      else value
      end
    end
  end
end
