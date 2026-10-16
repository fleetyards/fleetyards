# frozen_string_literal: true

module ScData
  # Which Model attachment a render from the ship-views bucket belongs on.
  #
  # The same rules as the admin's folder upload
  # (app/frontend/admin/components/Models/ViewsFolderUpload/mapping.ts), and
  # both are tested against test/fixtures/files/ship_view_filenames.json, so a
  # rule added on one side fails the other until it is ported.
  module ShipViewFields
    VIEW_NAME = /\A((?:extended|landed|flight)[-_ ]?)?(top|side|port|front|angled[-_ ]?rear|angled|bottom|rear|starboard)([-_ ]?view)?([-_ ]?colored)?\z/i
    HOLO_NAME = /\A((?:extended|landed|flight)[-_ ]?)?holo(?:[-_ ]?(lite|textured))?\z/i

    VIEWPOINTS = {
      "top" => "top",
      "side" => "port",
      "port" => "port",
      "front" => "front",
      "angled" => "angled",
      "angledrear" => "angled_rear",
      "bottom" => "bottom",
      "rear" => "rear",
      "starboard" => "starboard"
    }.freeze

    # A Blender export drops holo.blend, holo.obj and holo.mtl beside the glTF.
    VIEW_EXTENSIONS = %w[png jpg jpeg webp gif].freeze
    HOLO_EXTENSIONS = %w[gltf glb].freeze

    module_function

    # The attachment name, or nil for a file that has no field.
    def field_for(filename)
      basename = filename.split("/").last.to_s
      stem = basename.sub(/\.[^.]+\z/, "").strip
      extension = basename[(stem.length + 1)..].to_s.downcase

      if (holo = HOLO_NAME.match(stem))
        return unless HOLO_EXTENSIONS.include?(extension)

        prefix = prefix_for(holo[1])
        variant = holo[2]&.downcase

        # Only the flying pose is exported painted.
        return if variant == "textured" && prefix

        return [prefix, "holo", variant].compact.join("_")
      end

      view = VIEW_NAME.match(stem)
      return if view.nil? || !VIEW_EXTENSIONS.include?(extension)

      viewpoint = VIEWPOINTS.fetch(view[2].downcase.delete("-_ "))

      [prefix_for(view[1]), viewpoint, "view", ("colored" if view[4])].compact.join("_")
    end

    def prefix_for(state)
      state = state.to_s.downcase

      if state.start_with?("landed")
        "landed"
      elsif state.start_with?("extended")
        "extended"
      end
    end
  end
end
