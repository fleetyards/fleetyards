# frozen_string_literal: true

module ScData
  # The port list and the doors sc-tools exports beside a hull holo -- a ship's,
  # or a module's beside its item holo -- read and checked as one format.
  module HullExport
    # Where on the hull holo each item port sits. Parts are only mounted on a
    # ship's flying pose, so there is no landed set.
    HARDPOINT_TRANSFORMS_NAME = /\A(?:flight[-_ ]?)?hardpoints\.json\z/i
    # How the doors of the hull holo open. Older exports have none.
    DOORS_NAME = /\A(?:flight[-_ ]?)?doors\.json\z/i

    module_function

    def field_for(basename)
      return "hardpoint_transforms" if HARDPOINT_TRANSFORMS_NAME.match?(basename)

      "holo_doors" if DOORS_NAME.match?(basename)
    end

    # Checked on import rather than where it is served, so a malformed export
    # keeps the last good one instead of breaking the endpoint.
    def read(field, file)
      data = JSON.parse(file.read)

      (field == "holo_doors") ? doors(data) : hardpoint_transforms(data)
    end

    def hardpoint_transforms(transforms)
      raise ArgumentError, "no ports listed" unless transforms.is_a?(Hash) && transforms["ports"].is_a?(Array)

      transforms["ports"].each_with_index do |port, index|
        raise ArgumentError, "port #{index} is malformed" unless valid_port?(port)
      end

      Array(transforms["cargo_grids"]).each_with_index do |grid, index|
        raise ArgumentError, "cargo grid #{index} is malformed" unless valid_cargo_grid?(grid)
      end

      transforms
    end

    def doors(doors)
      raise ArgumentError, "no doors listed" unless doors.is_a?(Hash) && doors["doors"].is_a?(Array)

      doors["doors"].each_with_index do |door, index|
        raise ArgumentError, "door #{index} is malformed" unless valid_door?(door)
      end

      doors
    end

    def valid_port?(port)
      port.is_a?(Hash) &&
        port["name"].is_a?(String) &&
        numbers?(port["position"], 3) &&
        numbers?(port["rotation"], 4) &&
        (port["parent"].nil? || port["parent"].is_a?(String)) &&
        (port["defaultItem"].nil? || port["defaultItem"].is_a?(String)) &&
        (port["hullNode"].nil? || port["hullNode"].is_a?(String)) &&
        (port["itemKind"].nil? || port["itemKind"].is_a?(String)) &&
        Array(port["types"]).all? { |type| type.is_a?(Hash) && type["type"].is_a?(String) }
    end

    def valid_cargo_grid?(grid)
      grid.is_a?(Hash) &&
        grid["name"].is_a?(String) &&
        name_or_nil?(grid["port"]) &&
        name_or_nil?(grid["parentPort"]) &&
        numbers?(grid["position"], 3) &&
        numbers?(grid["rotation"], 4) &&
        numbers?(grid["size"], 3) &&
        (grid["scu"].nil? || grid["scu"].is_a?(Numeric))
    end

    def valid_door?(door)
      door.is_a?(Hash) &&
        door["id"].is_a?(String) &&
        name_or_nil?(door["kind"]) &&
        (door["position"].nil? || numbers?(door["position"], 3)) &&
        door["duration_s"].is_a?(Numeric) &&
        (door["obb_closed"].nil? || valid_bounds?(door["obb_closed"])) &&
        (door["outline"].nil? || valid_bounds?(door["outline"])) &&
        (door["outlineNodes"].nil? || (door["outlineNodes"].is_a?(Array) && door["outlineNodes"].all?(String))) &&
        door["parts"].is_a?(Array) &&
        door["parts"].all? { |part| valid_door_part?(part) }
    end

    def valid_bounds?(bounds)
      bounds.is_a?(Hash) &&
        numbers?(bounds["center"], 3) &&
        numbers?(bounds["half_size"], 3) &&
        bounds["axes"].is_a?(Array) &&
        bounds["axes"].size == 3 &&
        bounds["axes"].all? { |axis| numbers?(axis, 3) }
    end

    def valid_door_part?(part)
      return false unless part.is_a?(Hash) && part["motion"].is_a?(Hash)

      keyframes = part["motion"]["keyframes"]

      part["object"].is_a?(String) &&
        keyframes.is_a?(Array) &&
        keyframes.all? do |keyframe|
          keyframe.is_a?(Hash) &&
            keyframe["t"].is_a?(Numeric) &&
            numbers?(keyframe["translation"], 3) &&
            numbers?(keyframe["rotation"], 4)
        end
    end

    def name_or_nil?(value)
      value.nil? || value.is_a?(String)
    end

    def numbers?(value, size)
      value.is_a?(Array) && value.size == size && value.all?(Numeric)
    end
  end
end
