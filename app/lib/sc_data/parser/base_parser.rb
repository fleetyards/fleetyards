module ScData
  module Parser
    class BaseParser
      attr_accessor :base_path, :export_path, :import_path, :definition_path, :translations

      FOUNDRY_PATH = "Data/Libs/Foundry/Records"

      DDS_HEADER_BYTES = 128
      DDS_MIP_COUNT_OFFSET = 28

      SCU_DIMENSIONS = 1.25

      CARGO_CONTAINER_DIMENSIONS = [
        {
          size: 32,
          dimensions: {
            x: 8 * SCU_DIMENSIONS,
            y: 2 * SCU_DIMENSIONS,
            z: 2 * SCU_DIMENSIONS
          }
        },
        {
          size: 24,
          dimensions: {
            x: 6 * SCU_DIMENSIONS,
            y: 2 * SCU_DIMENSIONS,
            z: 2 * SCU_DIMENSIONS
          }
        },
        {
          size: 16,
          dimensions: {
            x: 4 * SCU_DIMENSIONS,
            y: 2 * SCU_DIMENSIONS,
            z: 2 * SCU_DIMENSIONS
          }
        },
        {
          size: 8,
          dimensions: {
            x: 2 * SCU_DIMENSIONS,
            y: 2 * SCU_DIMENSIONS,
            z: 2 * SCU_DIMENSIONS
          }
        },
        {
          size: 4,
          dimensions: {
            x: 2 * SCU_DIMENSIONS,
            y: 2 * SCU_DIMENSIONS,
            z: 1 * SCU_DIMENSIONS
          }
        },
        {
          size: 2,
          dimensions: {
            x: 2 * SCU_DIMENSIONS,
            y: 1 * SCU_DIMENSIONS,
            z: 1 * SCU_DIMENSIONS
          }
        },
        {
          size: 1,
          dimensions: {
            x: 1 * SCU_DIMENSIONS,
            y: 1 * SCU_DIMENSIONS,
            z: 1 * SCU_DIMENSIONS
          }
        }
      ]

      def self.all(base_folder:, sc_version:, sc_environment:)
        ::ScData::Parser::ItemsParser.new(base_folder:, sc_version:, sc_environment:).all
        ::ScData::Parser::ManufacturersParser.new(base_folder:, sc_version:, sc_environment:).all
        ::ScData::Parser::ModelsParser.new(base_folder:, sc_version:, sc_environment:).all
        ::ScData::Parser::CommoditiesParser.new(base_folder:, sc_version:, sc_environment:).all
        ::ScData::Parser::EquipmentParser.new(base_folder:, sc_version:, sc_environment:).all
      end

      def initialize(base_folder:, sc_version:, sc_environment:)
        self.base_path = "#{base_folder}/raw/#{sc_version}"
        self.export_path = "#{base_folder}/parsed/#{sc_environment}"
        self.import_path = "#{base_path}/#{FOUNDRY_PATH}"
        self.definition_path = "#{base_path}/Data"
        self.translations = parse_translations

        FileUtils.mkdir_p(export_path) unless File.directory?(export_path)

        File.write("#{export_path}/version.json", JSON.pretty_generate({
          version: sc_version,
          environment: sc_environment,
          parsed_at: Time.now.utc.iso8601
        }))
      end

      private def load_data(path)
        Dir.glob("#{import_path}/#{path}/**/*.xml").map do |file|
          data = Hash.from_xml(File.read(file))
          key = data.keys.first.split(".").last
          values = data.values.first

          {
            key:,
            values:
          }
        end
      end

      private def load_scripts_data(path)
        data = Hash.from_xml(File.read("#{definition_path}/#{path}"))
        key = data.keys.first.split(".").last
        values = data.values.first

        {
          key:,
          values:
        }
      rescue Errno::ENOENT => _e
        nil
      end

      private def save_items(items, folder:, key: :key, prefix: nil)
        return if items.blank?

        items_path = "#{export_path}/#{folder}"

        clear_once(items_path)

        FileUtils.mkdir_p(items_path) unless File.directory?(items_path)

        items.each do |item|
          file_name = [prefix, item[key].downcase].compact.join("_")

          p "Duplicate key: #{file_name}" if File.exist?("#{items_path}/#{file_name}.json")

          File.write("#{items_path}/#{file_name}.json", JSON.pretty_generate(item))
        end
      end

      # Records name their artwork as a path into the game files -- "UI/
      # SharedAssets/ManufacturerLogos/Talon_256.tif" -- and the export ships
      # the CryEngine texture beside it, .dds where the record says .tif. The
      # referenced ones convert to about 2 MB all told, against 128 MB for the
      # asset trees they sit in, so they are carried into the parsed tree here
      # rather than fetched from the bucket every time data is loaded.
      #
      # The written path mirrors the one the record names, extension aside, so
      # a loader can find it from what the record already stores.
      private def save_icon(icon_path)
        source = raw_asset(icon_path)

        return if source.blank?

        icons_path = "#{export_path}/icons"

        clear_once(icons_path)

        svg = File.extname(source).casecmp?(".svg")
        target = "#{icons_path}/#{icon_path.sub(/\.\w+\z/, svg ? ".svg" : ".png")}"

        FileUtils.mkdir_p(File.dirname(target))

        if svg
          FileUtils.cp(source, target)

          target
        else
          convert(source, target)
        end
      end

      private def convert(source, target)
        return target if png(source, target)

        rebuilt = reassemble(source)

        if rebuilt.blank?
          p "Could not convert #{source}"

          return
        end

        begin
          png(rebuilt.path, target) || p("Could not convert #{source} even reassembled")
        ensure
          rebuilt.close!
        end
      end

      # Twenty of the logo textures are CryEngine's split form: the .dds holds
      # the header and the smallest mips, and the rest sit beside it in
      # numbered companions -- GREY_256.dds is 464 bytes with its 256px surface
      # in GREY_256.dds.4. ImageMagick reads such a header, finds no surface
      # and exits, so the file is put back together first: the header with its
      # mip count set to one, followed by the largest companion.
      private def reassemble(source)
        companion = Dir.glob("#{source}.[0-9]*").max_by { |file| File.size(file) }

        return if companion.blank?

        header = File.binread(source, DDS_HEADER_BYTES).to_s

        return unless header.start_with?("DDS ") && header.bytesize == DDS_HEADER_BYTES

        header = header.dup
        header[DDS_MIP_COUNT_OFFSET, 4] = [1].pack("V")

        Tempfile.new(["sc_data_icon", ".dds"], binmode: true).tap do |file|
          file.write(header)
          file.write(File.binread(companion))
          file.flush
        end
      end

      private def png(source, target)
        return if source.blank?

        MiniMagick::Image.open(source).tap { |image| image.format("png") }.write(target)

        target
      rescue MiniMagick::Error
        nil
      end

      # Matched without the extension and without case: the records were
      # written against the source art, so they name .tif where the export
      # ships .dds, and neither side agrees on capitalisation.
      private def raw_asset(icon_path)
        return if icon_path.blank?

        raw_assets[icon_path.downcase.sub(/\.\w+\z/, "")]
      end

      private def raw_assets
        @raw_assets ||= Dir.glob("#{base_path}/Data/**/*.{dds,svg,png,tif}").to_h do |file|
          [file.delete_prefix("#{base_path}/Data/").downcase.sub(/\.\w+\z/, ""), file]
        end
      end

      # Writing is otherwise additive: a record the game files stopped carrying
      # keeps the file an earlier run wrote for it, and every later step reads
      # it back as part of the build -- which is what a loader retiring absent
      # records cannot see past.
      #
      # Emptied on the first write of a run rather than per call, because
      # `items` and `models` are filled by several passes and the later ones
      # must not wipe the earlier ones. That first write is also past the blank
      # check, so a pass that parsed nothing leaves what is on disk alone.
      private def clear_once(items_path)
        @cleared_paths ||= Set.new

        return unless @cleared_paths.add?(items_path)

        FileUtils.rm_rf(items_path)
      end

      private def parse_translations
        load_ini_file("#{base_path}/Data/Localization/english/global.ini")
      end

      # Cosmetic and prop entities, matched on whole key parts. Keep terms out
      # that can name real equipment: "interior" used to be here and silently
      # dropped the Ironclad's interior remote turrets (a tractor-beam arm and a
      # gun turret), while the interior props it was aimed at don't live under
      # the scanned `scitem/{ships,vehicles}` folders anyway.
      private def blacklisted_item_key?(key)
        [
          "camera", "panel", "animated", "light", "decal", "sensor", "button",
          "handle", "dashboard", "seataccess", "screen", "hud", "helper", "oc", "escape", "esc",
          "barrel", "firingmechanism", "powerarray", "ventilation", "mfd"
        ].any? do |filter|
          key.downcase.split("_").any? { |part| part == filter }
        end
      end

      private def translate(key)
        return nil if key.blank?
        return nil if key == "@LOC_EMPTY"

        return translations.dig(key.delete("@")) if key.starts_with?("@")

        key
      end

      private def load_ini_file(path)
        data = {}

        File.foreach(path, encoding: "bom|UTF-8") do |line|
          line = line.encode("UTF-8", invalid: :replace, undef: :replace).chomp

          unless /^\#/.match?(line)
            if /^([^=]+?)\s*=\s*(.*?)\s*$/.match?(line)
              param, val = line.split(/\s*=\s*/, 2)

              var_name = param.to_s.chomp.strip
              val = val.chomp.strip

              data[var_name] = val
            end
          end
        end

        data
      end

      private def value_or_nil(value)
        if value == "<= PLACEHOLDER =>" ||
            value == "UNDEFINED" ||
            value == "00000000-0000-0000-0000-000000000000" ||
            value.blank?
          return nil
        end

        value
      end
    end
  end
end
