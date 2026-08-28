# frozen_string_literal: true

module ScData
  # Which ships the game files describe that Fleetyards has no model for.
  #
  # Run at the end of a models load. Nothing here creates anything -- it records
  # what the export showed and reports what nobody has decided about yet.
  #
  # There is no rule that decides these. The export says what exists and what it
  # is made of, never whether a player can own it, and that is the only question
  # the catalogue cares about: `aegs_idris_p_collector_military` is mechanically
  # identical to the Idris-P and is an ownable collector version, while
  # `aegs_reclaimer_pu_hijacked` is mechanically identical to the Reclaimer and is
  # a mission prop. So this narrows the pile and describes each entry; a person
  # decides.
  class UnlistedModels
    # What the export names an NPC copy, a wreck or a template. 733 of the 894
    # unlisted files in the live tree carry one of these -- a single
    # `aegs_avenger_stalker` ships seven `_pu_ai_` variants. The same idea as
    # `WEAPON_VARIANT_KEYS`, which trims the weapon list from 175 to 133.
    MARKERS = %w[
      _pu_ai_ _ai_ _unmanned _template _derelict _wreck _dead _swarm _test _modifiers
    ].freeze

    # The in-game vendors that sell a loadout rather than a hull. What you earn
    # from Wikelo's Emporium or PYAM is the base ship carrying that fitting --
    # measured across the live tree, every one of these has the same mass, crew,
    # hull health and port list as the ship it extends, and changes only which
    # off-the-shelf component sits in each port. Nobody owns one either: across
    # 400 hangar syncs not a single vendor name appears.
    #
    # Matched on the export's display name rather than the identifier, because
    # that is where the vendor is written -- `mrai_guardian_military` ships as
    # "Mirai Guardian Wikelo War Special".
    #
    # **Only when a base ship resolves.** A vendor selling a hull the catalogue
    # does not have would have none, and has to stay reported.
    VENDOR_VARIANTS = /\b(wikelo|pyam)\b/i

    def initialize(source = ::ScData::Source.current, base_folder: nil)
      @source = source
      @base_folder = base_folder || Rails.root.join("data/sc_data")
    end

    attr_reader :source

    # Upserts a row per unlisted identifier and returns what a person still has
    # to look at. Seeing an identifier again only moves `last_seen_*`, so a
    # decision survives every later load.
    def run
      identifiers = unlisted_identifiers.reject { |identifier| vendor_variant?(identifier) }

      identifiers.each { |identifier| record(identifier) }

      # A row the rule now covers stops being reported. Only undecided ones go:
      # a decision that was already made is the record of it.
      ScDataUnlistedModel.undecided.where.not(identifier: identifiers).delete_all

      {
        seen: identifiers.size,
        new: ScDataUnlistedModel.undecided.first_seen_in(source).where(identifier: identifiers).order(:identifier).to_a,
        undecided: ScDataUnlistedModel.undecided.order(:identifier).to_a
      }
    end

    # Only a genuinely new entry is worth interrupting somebody for. The pile that
    # has been sitting undecided is reported as a count, not as a list.
    def self.actionable?(result)
      result[:new].present?
    end

    def self.report_body(result, source = ::ScData::Source.current)
      lines = ["## New in #{source.environment} #{source.version} (#{result[:new].size})", ""]

      if result[:new].empty?
        lines << "Nothing the export shows is new to us."
      else
        result[:new].first(LISTED).each { |entry| lines << "- #{describe(entry)}" }
        lines << "- …and #{result[:new].size - LISTED} more" if result[:new].size > LISTED
      end

      lines << ""
      lines << "## Still undecided (#{result[:undecided].size})"
      lines << ""

      result[:undecided].group_by(&:comparison).sort_by { |_, list| -list.size }.each do |comparison, list|
        lines << "- #{COMPARISON_LABELS.fetch(comparison, comparison)}: #{list.size}"
      end

      unknown = result[:undecided].count(&:unknown_manufacturer?)
      if unknown.positive?
        lines << ""
        lines << "#{unknown} name a prefix no ship in the catalogue uses — a new company, or not a ship."
      end

      lines.join("\n")
    end

    LISTED = 25

    COMPARISON_LABELS = {
      "identical" => "identical to the ship they extend",
      "refitted" => "same hull, different stock loadout",
      "structural" => "a different machine",
      "unrelated" => "no base ship in the catalogue"
    }.freeze

    def self.describe(entry)
      parts = ["**#{entry.identifier}**"]
      parts << entry.name if entry.name.present?
      parts << (entry.base_model ? "#{COMPARISON_LABELS.fetch(entry.comparison, entry.comparison)} — #{entry.base_model.name}" : "no base ship")
      parts << (entry.manufacturer_code.presence || "unknown manufacturer")

      parts.join(" · ")
    end

    private

    def export_path
      Pathname(@base_folder).join("parsed", source.environment.to_s)
    end

    def parsed_identifiers
      Dir.glob(export_path.join("models", "*.json")).map { |file| File.basename(file, ".json") }
    end

    # Everything the export ships, less what the catalogue already has and less
    # what announces itself as not a ship.
    def unlisted_identifiers
      known = Model.all.filter_map(&:sc_data_identifier).to_set

      parsed_identifiers.reject do |identifier|
        known.include?(identifier) || MARKERS.any? { |marker| identifier.include?(marker) }
      end
    end

    # A loadout an in-game vendor sells, on a hull the catalogue already has.
    def vendor_variant?(identifier)
      data = load(identifier)
      return false if data.nil?
      return false unless data["name"].to_s.match?(VENDOR_VARIANTS)

      base_model_for(identifier).present?
    end

    def record(identifier)
      entry = ScDataUnlistedModel.find_or_initialize_by(identifier:)

      if entry.new_record?
        entry.first_seen_version = source.version
        entry.first_seen_environment = source.environment
      end

      entry.last_seen_version = source.version
      entry.last_seen_environment = source.environment

      # Refreshed on every run rather than only on creation: a base ship the
      # catalogue gained since, or a manufacturer the mapping learned, should
      # show up without the row having to be deleted.
      data = load(identifier)
      base = base_model_for(identifier)

      entry.name = data&.dig("name")
      entry.manufacturer_code = ::ScData::ManufacturerMapping.code_for(identifier)
      entry.base_model = base
      entry.comparison = compare(data, base)

      entry.save!
    end

    def load(identifier)
      path = export_path.join("models", "#{identifier}.json")

      JSON.parse(path.read) if path.exist?
    end

    # The longest model identifier this one extends. `anvl_ballista_ea_outlaw`
    # resolves to the Ballista.
    def base_model_for(identifier)
      stem = models_by_identifier.keys.select { |known| identifier.start_with?("#{known}_") }.max_by(&:length)

      models_by_identifier[stem] if stem
    end

    def models_by_identifier
      @models_by_identifier ||= Model.all.index_by(&:sc_data_identifier).except(nil)
    end

    # Descriptive, not a verdict. `refitted` is the same hull with different
    # components in the same ports -- which is what both a referral bonus and an
    # in-game-only special look like.
    def compare(data, base)
      return "unrelated" if base.nil?
      return if data.nil?

      base_data = load(base.sc_data_identifier)
      return if base_data.nil?

      a = ports(base_data)
      b = ports(data)

      return "structural" if a.keys.sort != b.keys.sort ||
        base_data["mass"] != data["mass"] ||
        base_data["min_crew"] != data["min_crew"] ||
        base_data["hull_health"] != data["hull_health"]

      (a == b) ? "identical" : "refitted"
    end

    def ports(data)
      Array(data["loadout"]).to_h { |port| [port["name"], port["ref"]] }
    end
  end
end
