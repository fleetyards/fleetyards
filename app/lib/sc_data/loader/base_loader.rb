module ScData
  module Loader
    class BaseLoader
      DEFAULT_BASE_FOLDER = Rails.root.join("data/sc_data").freeze

      attr_accessor :sc_version, :sc_environment, :base_folder

      # Returns what each loader did, so the job that ran it can keep the counts
      # on its import rather than leaving them only in the log.
      #
      # The classes are listed inside the method rather than in a constant: every
      # one of them subclasses BaseLoader, so resolving them while this class
      # body is still being evaluated would be a circular load.
      #
      # Order matters -- items resolve their manufacturer, models resolve the
      # components a loadout names, and modules hang off models.
      def self.all
        [
          ::ScData::Loader::ManufacturersLoader,
          ::ScData::Loader::ItemsLoader,
          ::ScData::Loader::ModelsLoader,
          ::ScData::Loader::ModelModulesLoader,
          ::ScData::Loader::CommoditiesLoader,
          ::ScData::Loader::EquipmentLoader
        ].to_h do |loader_class|
          loader = loader_class.new

          loader.all

          Rails.logger.info("[sc_data] #{loader_class.name.demodulize}: #{loader.stats_summary}")

          [loader_class.name.demodulize, loader.stats]
        end
      end

      def initialize(base_folder: DEFAULT_BASE_FOLDER)
        source = ::ScData::Source.current

        self.base_folder = base_folder
        self.sc_version = source.version
        self.sc_environment = source.environment
      end

      # Read on every call rather than built in the constructor: callers set
      # `sc_environment` on a loader they already have -- a load of the
      # preview tree is the same loader pointed somewhere else.
      def export_path
        Pathname(base_folder).join("parsed", sc_environment.to_s)
      end

      # What this run actually did, per model class. `update!` on its own cannot
      # tell a row it rewrote from a row it left alone, so a load that changed
      # nothing and a load that rewrote the catalogue look identical in the logs
      # -- which is exactly what you want to know when a build lands badly.
      def stats
        @stats ||= Hash.new { |all, name| all[name] = {created: 0, updated: 0, unchanged: 0} }
      end

      def stats_summary
        return "nothing written" if stats.empty?

        stats.sort.map { |name, counts|
          "#{name} #{counts.map { |bucket, count| "#{bucket}=#{count}" }.join(" ")}"
        }.join(", ")
      end

      # The one write path a load takes. Assigning before saving is what makes
      # the three outcomes distinguishable; `update!` would collapse them.
      def apply(record, params)
        created = record.new_record?

        record.assign_attributes(params)
        changed = record.changed?

        record.save!

        count(record, outcome(created:, changed:))

        record
      end

      # Validations and callbacks are skipped on purpose where this is used: it
      # sweeps every Model on every load, and the in-game flag is not something
      # a validation or a stored version has an opinion about.
      def apply_columns(record, params)
        record.update_columns(params)

        count(record, :updated)

        record
      end

      private def outcome(created:, changed:)
        return :created if created
        return :updated if changed

        :unchanged
      end

      private def count(record, bucket)
        stats[record.class.name][bucket] += 1
      end

      def load_item(path)
        file_path = export_path.join("#{path}.json")

        return unless file_path.exist?

        JSON.parse(file_path.read)
      end

      def find_item_by_ref(path, ref)
        load_items(path).find { |item| item[:ref] == ref }
      end

      def find_item_by_key(path, key)
        load_items(path).find { |item| item[:key] == key }
      end

      def load_items(path)
        Dir.glob(export_path.join(path, "**", "*.json")).map do |file|
          JSON.parse(File.read(file)).with_indifferent_access
        end
      end

      def lookup_manufacturer(ref)
        Manufacturer.find_by(sc_ref: ref)
      end

      # The parser carried the artwork into the parsed tree, so attaching it is
      # a local read -- no bucket, no credentials, and it works offline.
      #
      # Guarded on the checksum ActiveStorage itself stores, because attaching
      # an identical file writes a fresh blob every time: a load that changed
      # nothing would otherwise leave a few hundred orphans behind on each run.
      # Nothing is detached when the export stops naming artwork: these
      # attachments are also where an admin's own upload lives -- the eight
      # manufacturers the game names no logo for are exactly the ones somebody
      # filled in by hand -- and a load cannot tell one from the other. A path
      # that changes still replaces what it put there, since the checksum moves
      # with it.
      def attach_icon(record, attachment_name, icon_path)
        file = parsed_icon(icon_path)

        return if file.blank?

        attachment = record.public_send(attachment_name)
        checksum = Digest::MD5.file(file).base64digest

        return if attachment.attached? && attachment.blob.checksum == checksum

        File.open(file) do |io|
          attachment.attach(
            io:,
            filename: File.basename(file),
            content_type: Marcel::MimeType.for(name: File.basename(file))
          )
        end
      end

      # The record names the source art -- .tif -- while what was written is the
      # picture the export ships for it, a .png or an .svg, under a path that
      # otherwise matches.
      def parsed_icon(icon_path)
        return if icon_path.blank?

        Dir.glob(
          export_path.join("icons", "#{icon_path.sub(/\.\w+\z/, "")}.*")
        ).first
      end

      # A record the export dropped keeps its row -- a ledger entry or a loadout
      # made against it still has to resolve -- but it must stop claiming a
      # build it is no longer part of, or `current_version` would go on
      # offering it.
      #
      # Re-importing the same build is what makes this necessary: a new build
      # leaves the row on its old version, but a reload of the one we are
      # already on leaves it looking current.
      #
      # A run that loaded nothing retires nothing. `where.not(id: [])` is
      # `1=1`, so an export that failed to sync -- or an environment whose tree
      # does not carry this catalogue at all -- would otherwise take the whole
      # of it in one statement.
      def retire_absent(model, loaded)
        return if loaded.blank?

        model.where(version: sc_version).where.not(id: loaded).update_all(version: nil)
      end

      def update_cargo_holds(hardpoints, update_params)
        cargo_holds = extract_cargo_holds(hardpoints)

        return update_params if cargo_holds.blank?

        update_params[:cargo_holds] = cargo_holds

        update_params
      end

      def extract_type_data(hardpoints, component_type)
        hardpoints.filter_map do |hardpoint|
          if hardpoint.hardpoints.present?
            extract_type_data(hardpoint.hardpoints, component_type)
          else
            next if hardpoint.component.blank?
            next if hardpoint.component.component_type != component_type

            hardpoint.component.type_data
          end
        end.flatten
      end

      def extract_named_type_data(hardpoints, component_type)
        hardpoints.sort_by { |h| h.sc_name.to_s }.filter_map do |hardpoint|
          if hardpoint.hardpoints.present?
            extract_named_type_data(hardpoint.hardpoints, component_type)
          else
            next if hardpoint.component.blank?
            next if hardpoint.component.component_type != component_type

            (hardpoint.component.type_data || {}).merge(
              "name" => hardpoint.sc_name,
              "component_name" => hardpoint.component.name
            )
          end
        end.flatten
      end

      def extract_cargo_holds(hardpoints)
        hardpoints.sort_by { |h| h.sc_name.to_s }.filter_map do |hardpoint|
          if hardpoint.hardpoints.present?
            extract_cargo_holds(hardpoint.hardpoints)
          else
            next if hardpoint.component.blank?
            next if hardpoint.component.component_type != "CargoGrid"

            hardpoint.component.type_data&.merge("name" => hardpoint.sc_name)
          end
        end.flatten
      end

      # One hardpoint the loadout says should exist: resolved, but unwritten.
      # This is the handover between working out what a loadout means and making
      # rows match it -- two jobs that used to be one recursive method that wrote
      # as it walked, which is why the rules could not be exercised without a
      # database and why the destructive cleanup sat in the middle of them.
      Slot = Struct.new(:name, :component, :children, :retain_only)

      private def update_loadout(parent, loadout, cleanup: true)
        # The module-key derivation below only applies to a ship. A module's own
        # loadout, and every nested level, resolves without it.
        slots = resolve_loadout(loadout, model: (parent if parent.is_a?(Model)))

        persist_loadout(parent, slots, cleanup:)
      end

      # Nothing past here writes: the only database access is what it takes to
      # turn a key or a ref into a component.
      private def resolve_loadout(loadout, model: nil)
        entries = loadout["loadout"] || loadout["default_loadout"]

        entries.flat_map { |item| resolve_item(loadout, item, model:) }
      end

      private def resolve_item(loadout, item, model:)
        default_loadout = loadout["default_loadout"]&.find { |dl| dl["name"] == item["name"] }

        return [] if loadout_name_blacklisted?(item["name"], default_loadout)

        item = adopt_default_loadout(item, default_loadout)
        item = derive_module_key(item, model)

        component = resolve_component(item)

        return flatten_hidden(item, component) if component&.hidden?

        [Slot.new(name: item["name"].downcase, component:, children: nested_slots(item))]
      end

      # A hidden component is a container the game files ship as an item -- a
      # door that holds a cargo grid. It gets no hardpoint of its own; its
      # sub-hardpoints are promoted onto this level under a compound name.
      private def flatten_hidden(item, component)
        nested_loadout = item["loadout"] || item["default_loadout"]

        promoted = component.hardpoints.filter_map do |sub_hardpoint|
          sub_component = sub_hardpoint.component ||
            nested_component(nested_loadout, sub_hardpoint)

          next if sub_component.blank?
          next if loadout_name_blacklisted?(sub_component.sc_key)

          Slot.new(
            name: "#{item["name"]}-#{sub_hardpoint.sc_name}".downcase,
            component: sub_component,
            children: []
          )
        end

        # Carried over deliberately: the hardpoint under the hidden component's
        # own name used to be looked up before the code knew the component was
        # hidden, and the id that collected protected the row from cleanup. So a
        # row left from a build where the component was not hidden survives,
        # still naming the component the flattening was meant to replace.
        promoted + [Slot.new(name: item["name"].downcase, retain_only: true, children: [])]
      end

      # The items loader cannot always resolve a hidden component's own
      # sub-hardpoints, so the loadout being walked is consulted to fill the gap.
      private def nested_component(nested_loadout, sub_hardpoint)
        return if nested_loadout.blank?

        nested = nested_loadout.find { |entry| entry["name"]&.downcase == sub_hardpoint.sc_name }

        return if nested.blank?

        resolve_component(nested)
      end

      # Resolved by key alone when a key is present: a component is one row now,
      # and `version` says which build it was last seen in rather than which row
      # to use. A key that fails to resolve does not fall through to the ref.
      private def resolve_component(item)
        if item["key"].present?
          Component.find_by(sc_key: item["key"]&.downcase)
        elsif item["ref"].present?
          Component.find_by(sc_ref: item["ref"])
        end
      end

      # Matched on the raw name, case-sensitively, while the row is keyed on the
      # downcased one -- so a default whose capitalisation differs is not
      # applied. Merged rather than assigned into: the parsed hash belongs to
      # the caller, and a nested level reads the adopted default off the copy.
      private def adopt_default_loadout(item, default_loadout)
        return item if item["key"].present? || default_loadout.blank?

        adopted = item.merge("key" => default_loadout["key"], "ref" => default_loadout["ref"])

        return adopted if default_loadout["default_loadout"].blank?

        adopted.merge("default_loadout" => default_loadout["default_loadout"])
      end

      # A module hardpoint the export names but does not key, whose component is
      # named after the ship carrying it.
      private def derive_module_key(item, model)
        return item if model.blank?
        return item if item["key"].present? || item["ref"].present?
        return item unless item["name"]&.end_with?("_module")

        derived_key = "#{model.sc_data_identifier}_module"

        return item unless Component.exists?(sc_key: derived_key)

        item.merge("key" => derived_key)
      end

      private def nested_slots(item)
        return [] if item["loadout"].blank? && item["default_loadout"].blank?

        resolve_loadout(item)
      end

      private def persist_loadout(parent, slots, cleanup: true)
        hardpoint_ids = slots.filter_map { |slot| persist_slot(parent, slot) }

        parent.hardpoints.where(source: :game_files).where.not(id: hardpoint_ids).destroy_all if cleanup

        hardpoint_ids
      end

      private def persist_slot(parent, slot)
        hardpoint = parent.hardpoints.find_or_initialize_by(sc_name: slot.name)

        return hardpoint.persisted? ? hardpoint.id : nil if slot.retain_only

        update_params = {source: :game_files, component: slot.component}

        if slot.component.present?
          update_params[:min_size] = slot.component.size
          update_params[:max_size] = slot.component.size
        end

        apply(hardpoint, update_params)

        persist_loadout(hardpoint, slot.children) if slot.children.present?

        hardpoint.id
      end

      private def loadout_name_blacklisted?(name, default_loadout = nil)
        blacklist = [
          "aegs_retaliator_door_cap_rear", "aegs_retaliator_door_cap_front", # Retaliator door caps
          "rsi_constellation_ph_baywall_right", "rsi_constellation_ph_baywall_left", # Constellation Pheonix bay walls
          "rsi_constellation_base_baywall_right", "rsi_constellation_base_baywall_left" # Constellation Base bay walls
        ]

        # Fuel pod consoles / refuel terminals: cosmetic Display items used to operate
        # refueling in-cabin; not useful as loadout entries.
        blacklist_patterns = [
          /\Ahardpoint_fuelpod_\d+_console\z/,
          /\Ahardpoint_console_catwalk\z/,
          /\Ahardpoint_refuel_console\z/
        ]

        if default_loadout.present?
          return blacklist.include?(default_loadout["key"]&.downcase) || blacklist.include?(default_loadout["ref"])
        end

        return true if name && blacklist_patterns.any? { |pattern| pattern.match?(name.downcase) }

        blacklist.include?(name&.downcase)
      end
    end
  end
end
