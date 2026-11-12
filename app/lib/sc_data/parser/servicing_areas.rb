module ScData
  module Parser
    # Where on a ship a landed ship gets serviced. A ship whose
    # `ShipServicesProviderParams` sets `useZoneServicing` services only inside
    # the areas its object containers place with the `ShipServicingArea` tag --
    # on a Liberator its vehicle bay, on an Ironclad Assault its repair bay. No
    # record names those areas; they exist only in the level data, which the
    # exporter reduces to `derived/shipcontainers.json`.
    #
    # A ship's areas are the ones in the containers its record lists and every
    # container those nest. Positions stay local to the container the area sits
    # in, with the offset the ship's record places the outermost one at.
    class ServicingAreas
      CONTAINERS_FILE = "derived/shipcontainers.json"

      def initialize(base_path:)
        @base_path = base_path
      end

      def for(values)
        roots = Array.wrap(values.dig("Components", "VehicleComponentParams", "objectContainers", "SVehicleObjectContainerParams"))

        roots.flat_map do |root|
          key = container_key(root["fileName"])
          next [] if key.blank?

          walk(key).flat_map do |container|
            Array.wrap(containers.dig(container, "servicingAreas")).map do |area|
              {
                name: area["name"],
                container:,
                root_container: key,
                bone: root["boneName"].presence,
                offset: offset(root["Offset"]),
                position: area["position"],
                rotation: area["rotation"],
                shapes: area["shapes"]
              }.compact
            end
          end
        end.uniq { |area| [area[:container], area[:name]] }
      end

      private def walk(key, seen = Set.new)
        return [] unless containers.key?(key) && seen.add?(key)

        [key] + Array.wrap(containers.dig(key, "children")).flat_map { |child| walk(child, seen) }
      end

      private def offset(value)
        return if value.blank?

        position = value["Position"]
        rotation = value["Rotation"]

        {
          position: position && %w[x y z].map { |axis| position[axis].to_f },
          rotation: rotation && %w[x y z].map { |axis| rotation[axis].to_f }
        }.compact.presence
      end

      private def container_key(file_name)
        file_name.to_s.tr("\\", "/").downcase.presence
      end

      private def containers
        @containers ||= begin
          file = "#{@base_path}/#{CONTAINERS_FILE}"
          File.exist?(file) ? JSON.parse(File.read(file))["containers"] || {} : {}
        end
      end
    end
  end
end
