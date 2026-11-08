# frozen_string_literal: true

module ScData
  # Attaches the rigged base bodies sc-tools publishes under `characters/` to a
  # CharacterBody per listed body, creating the record the first time a body
  # is listed: the rest-pose body, the clips that pose it and the face library
  # that reshapes its head.
  class CharacterBodiesImportJob < ApplicationJob
    include RenderImport

    sidekiq_options queue: "loaders"

    SKIN_TONE = /\A#\h{6}\z/

    FIELDS = {"body.glb" => "holo", "body_textured.glb" => "holo_textured", "animations.glb" => "animations"}.freeze

    def perform
      return unless ::ScData::CharacterStore.configured?

      store = ::ScData::CharacterStore.new
      attached = {}
      manifest = store.manifest
      rigs = lighting_rigs(store, manifest)
      faces = ::ScData::CharacterFacesImport.new(store)

      store.characters(manifest).each do |key, entry|
        body = CharacterBody.find_or_create_by!(key:)
        clips = entry["clips"].map { |clip| clip.slice("name", "static", "looping") }
        weapon_in_hand = weapon_in_hand(entry["weapon_in_hand"])
        body.update_columns(clips:) if body.clips != clips
        body.update_columns(weapon_in_hand:) if body.weapon_in_hand != weapon_in_hand
        skin_tone = entry["skin_tone"] if entry["skin_tone"].to_s.match?(SKIN_TONE)
        body.update_columns(skin_tone:) if body.skin_tone != skin_tone
        unless rigs.nil?
          lighting = lights(rigs.dig("review_#{key}", "lights"))
          body.update_columns(lighting:) if body.lighting != lighting
        end

        if entry["faces"]
          face_fields = faces.call(body, entry["faces"])
          attached["#{key} faces"] = face_fields if face_fields.any?
        end

        # The index has no digest of its own for a body, so its file list is,
        # with the names this job reads: a file listed before the job learned
        # its name would otherwise stay skipped until the export changes.
        digest = Digest::MD5.hexdigest([FIELDS.keys, entry["files"].sort].to_json)
        next if body.views_digest == digest

        fields = import(store, body, entry["path"], digest, listing: {"files" => entry["files"]})
        attached[key] = fields if fields.any?
      rescue => e
        log(:error, "#{key} failed: #{e.class}: #{e.message}")
        Appsignal.report_error(e)
      end

      attached.each { |key, fields| log(:info, "attached #{key}: #{fields.join(", ")}") }
    end

    # A rig that cannot be read leaves the bodies lit as they were: nil, where
    # an export that lists no lighting at all is an empty rig.
    private def lighting_rigs(store, manifest)
      store.lighting_rigs(manifest)
    rescue => e
      log(:warn, "lighting could not be read: #{e.class}: #{e.message}")
      nil
    end

    LIGHT_TYPES = %w[spot point].freeze

    # The lights three.js needs, each kept only whole: a type, a position,
    # a colour and an intensity, and for a spot its direction and cone.
    private def lights(list)
      Array.wrap(list).filter_map do |light|
        next unless light.is_a?(Hash) && LIGHT_TYPES.include?(light["type"])
        next unless numbers?(light["position"], 3) && numbers?(light["color"], 3) && light["intensity"].is_a?(Numeric)

        spot = light["type"] == "spot"
        next if spot && !numbers?(light["direction"], 3)

        # The rest is optional, and kept only as a number.
        {
          "type" => light["type"],
          "position" => light["position"],
          "direction" => (light["direction"] if spot),
          "color" => light["color"],
          "intensity" => light["intensity"],
          "range" => number(light["range"]),
          "decay" => number(light["decay"]),
          "angle" => (number(light.dig("three", "angle")) || number(light["outerConeAngle"]) if spot),
          "penumbra" => (number(light.dig("three", "penumbra")) if spot)
        }.compact
      end
    end

    # Kept only whole: both hand bones, and a helper with a position and a
    # rotation. A partial one would break the payload's own schema.
    private def weapon_in_hand(value)
      return unless value.is_a?(Hash)

      bones = value["bones"]
      helper = value["helper"]
      return unless bones.is_a?(Hash) && bones["right"].is_a?(String) && bones["left"].is_a?(String)
      return unless helper.is_a?(Hash) && numbers?(helper["position"], 3) && numbers?(helper["rotation"], 4)

      {"bones" => bones.slice("right", "left"), "helper" => helper.slice("position", "rotation")}
    end

    private def number(value) = (value if value.is_a?(Numeric))

    private def numbers?(values, count)
      values.is_a?(Array) && values.size == count && values.all?(Numeric)
    end

    private def field_for(name) = FIELDS[name]

    private def render_metadata(_record, _field) = {}

    private def render_md5s_column = :view_md5s

    private def render_digest_column = :views_digest

    private def log(level, message)
      Rails.logger.public_send(level, "[sc_data] CharacterBodiesImportJob #{message}")
    end
  end
end
