# frozen_string_literal: true

module Locations
  # Every jump point in the listed systems, with the system it leads to.
  #
  # The key names both ends -- JumpPoint_Pyro_Nyx -- but not always truthfully:
  # the game reuses placeholder records for tunnels it has not named yet. The
  # Stanton-Nyx tunnel is JumpPoint_Stanton_Magnus and JumpPoint_Nyx_Castra, and
  # only the rest stop each one sits under says where it goes: "Nyx Gateway",
  # "Stanton Gateway". So a gateway's name wins over the key.
  class JumpPoints
    KEY = /\AJumpPoint_[A-Za-z]+_([A-Za-z]+)\z/
    GATEWAY_NAME = /\A(.+) Gateway\z/

    Entry = Struct.new(:location, :system_id, :destination_name, :destination_system_id)

    def call
      jump_points.filter_map do |point|
        destination = destination_of(point)
        next if destination.blank?

        Entry.new(
          location: point,
          system_id: point.system_id,
          destination_name: destination,
          destination_system_id: systems[destination.downcase]&.id
        )
      end
    end

    # The wreck site at the Stanton-Pyro jump point is a jump point by kind but
    # has a third part to its key, so it never matches.
    private def destination_of(point)
      key_destination = point.sc_key[KEY, 1]
      return if key_destination.blank?

      gateway_destination(point.parent) || key_destination
    end

    private def gateway_destination(parent)
      return if parent.blank? || !parent.sc_key.match?(::Locations::Tree::GATEWAY_KEY)

      parent.name.to_s[GATEWAY_NAME, 1]
    end

    private def jump_points
      Location.listed.current_version
        .where("locations.sc_key LIKE ?", "JumpPoint\\_%")
        .includes({parent: [:build, :last_build]}, :build, :last_build)
        .order(:sc_key)
    end

    # By the name the game gives a system in its jump point keys: NyxSolarSystem
    # is "nyx".
    private def systems
      @systems ||= Location.listed.current_version
        .where("locations.sc_key LIKE ?", "%SolarSystem")
        .index_by { |system| system.sc_key.delete_suffix("SolarSystem").downcase }
    end
  end
end
