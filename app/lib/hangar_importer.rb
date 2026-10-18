class HangarImporter
  attr_accessor :import

  MODEL_FIND_QUERY = [
    "lower(name) = :name",
    "lower(rsi_name) = :name",
    "slug = :slug",
    "rsi_slug = :slug",
    "lower(name) = :normalized_name",
    "lower(rsi_name) = :normalized_name",
    "slug = :normalized_name",
    "rsi_slug = :normalized_name"
  ].freeze

  MODEL_LEGACY_SLUG_QUERY = [
    "legacy_slug = :slug",
    "legacy_slug = :normalized_name"
  ].freeze

  # How often the run looks up whether the user has asked it to stop. A single
  # column read, not a `reload`: reloading would fetch the whole `import_data`
  # YAML blob back from the database on every check.
  CANCEL_CHECK_INTERVAL = 25

  HANGAR_XPLOR_SHIP_NAMES = YAML.load_file(Rails.root.join("config/hangar_xplor_ship_names.yml")).freeze

  def initialize(import)
    @import = import
  end

  def run
    # Cancelled while it was still queued -- there is nothing to start, and
    # `start` has no transition out of `cancelled`.
    return if @import.cancelled?

    @import.start!

    missing_models = []
    imported_models = []

    # An import creates the user's hangar wholesale; none of it is an edit the
    # user made to a ship that already existed.
    cancelled = false

    items = @import.import_data || []

    PaperTrail.request(enabled: false) do
      items.each_with_index do |item, index|
        if stop_requested?(index)
          cancelled = true
          break
        end

        # The Star Citizen: Hangar Extension writes its own export alias to
        # `name` and the ship-matrix name to `matrix`. The alias is the one that
        # misleads -- "F7C-M Super Hornet Heartseeker" maps to the plain Super
        # Hornet -- so the matrix name goes first.
        names = [item[:matrix], item[:name]].compact_blank.uniq.map { |raw| mapped_name(raw) }

        slug = item[:slug].downcase if item[:slug].present?
        slug = item[:paint_slug].downcase if item[:paint_slug].present?

        # Neither half of the query can match on an item that names nothing, and
        # it has no label to report either.
        next if names.empty? && slug.blank?

        params = {
          notify: false,
          user_id: @import.user_id,
          # An export carries whatever serial the ship had, including ones from
          # before the game format; one of those would fail validation and lose
          # the whole ship rather than just its serial.
          serial: Vehicle.game_serial(item[:ship_serial]),
          flagship: item[:flagship] || false,
          wanted: item[:wanted] || false,
          bought_via: item[:bought_via] || :pledge_store,
          public: item[:public] || false,
          name_visible: item[:name_visible] || false,
          sale_notify: item[:sale_notify] || false,
          hangar_group_ids: hangar_group_ids_for(item),
          model_module_ids: ModelModule.where(name: (item[:modules] || []) + (legacy_module_mapping[item["name"]] || [])).pluck(:id),
          model_upgrade_ids: ModelUpgrade.where(name: item[:upgrades]).pluck(:id)
        }

        model, model_paint = find_model_or_paint(names, slug)
        if model.present?
          Vehicle.create(params.merge(
            model_id: model.id,
            name: custom_name(item, model),
            model_paint_ids: owned_paint_ids(item, model.id)
          ))
          imported_models << model.name
          next
        end

        # An export from before owned paints names the one paint a ship had in
        # `paint_slug`, which is what `slug` was set to above.
        if model_paint.present?
          Vehicle.create(params.merge(
            model_id: model_paint.model_id,
            name: custom_name(item, model_paint.model),
            model_paint_ids: owned_paint_ids(item, model_paint.model_id) | [model_paint.id]
          ))
          imported_models << model_paint.name
          next
        end

        # The identifier the lookup actually used: `slug` already holds
        # `paint_slug` where the item carried one. Reporting `item[:slug]`
        # instead would name a slug that was never queried, and on an item that
        # carried only a paint it would report nothing -- `missing` is sorted,
        # and one nil beside a string raises rather than naming either.
        missing_models << (item[:matrix].presence || item[:name].presence || slug)
      end
    end

    Vehicle.where(user_id: @import.user_id).update_all(notify: true)

    # The loop's own flag, or a cancellation that landed after its last
    # checkpoint. Asking once means `output` and the transition below cannot
    # disagree about whether the run was cancelled.
    cancelled ||= @import.reload.cancelled?

    output = {
      missing: missing_models.sort,
      imported: imported_models.sort,
      # `missing_models.size < items.size` counted an item the run skipped as a
      # success, so a file of nothing but unidentifiable entries reported one.
      success: !cancelled && imported_models.any?
    }

    @import.update!(output: output)

    # A run that finishes inside the window between the transition and the next
    # checkpoint would otherwise fire `finish` from `cancelled` and raise
    # `AASM::InvalidTransition`. The state has already moved; there is nothing
    # left to transition.
    @import.finish! unless cancelled

    output
  rescue => e
    # `fail` has no transition out of `cancelled`, and raising over the original
    # exception would hide what actually went wrong.
    @import.fail! if @import.may_fail?
    @import.update!(info: e.message)

    raise e
  end

  # The group the user aimed this run at overrides whatever the file says: they
  # picked it while starting the import, and the per-item names are the
  # fallback for a plain re-import that expressed no preference.
  # The paints an export says the ship owns: `paint_slugs`, or the single
  # `paint_slug` an older export carried. Only the model's own count.
  private def owned_paint_ids(item, model_id)
    slugs = (Array(item[:paint_slugs]) + [item[:paint_slug]]).compact_blank.map { |slug| slug.to_s.downcase }
    return [] if slugs.empty?

    ModelPaint.where(model_id:, slug: slugs).pluck(:id)
  end

  private def hangar_group_ids_for(item)
    return [@import.hangar_group_id] if @import.hangar_group_id.present?

    HangarGroup.where(user_id: @import.user_id, name: item[:groups]).pluck(:id)
  end

  # `custom_name` comes only from older Fleetyards exports, so it is always the
  # owner's; `ship_name` may be Hangar XPLORer's standard name.
  private def custom_name(item, model)
    ship_name = item[:ship_name]
    return ship_name if ship_name.present? && !hangar_xplor_standard_name?(item, model, ship_name)

    item[:custom_name].presence
  end

  # Hangar XPLORer exports a ship's standard name in `ship_name` unless its
  # owner named it. Only its rows carry a `pledge_id`, and a ship newer than the
  # vendored list falls back to the names the row and the model already give.
  private def hangar_xplor_standard_name?(item, model, name)
    return false if item[:pledge_id].blank?

    [HANGAR_XPLOR_SHIP_NAMES[item[:ship_code]], item[:name], model.name, model.rsi_name]
      .compact_blank
      .any? { |standard_name| standard_name.to_s.squish.casecmp?(name.to_s.squish) }
  end

  # Each name in turn, the model before a paint, so a paint matched by the
  # first name never shadows a model matched by the second.
  private def find_model_or_paint(names, slug)
    (names.presence || [nil]).each do |name|
      normalized_name = normalize(name)
      binds = {name: name&.downcase, slug:, normalized_name:}

      model = Model.where((MODEL_FIND_QUERY + MODEL_LEGACY_SLUG_QUERY).join(" OR "), binds).first
      return [model, nil] if model.present?

      model_paint = ModelPaint.includes(:model).where(MODEL_FIND_QUERY.join(" OR "), binds).first
      return [nil, model_paint] if model_paint.present?
    end

    [nil, nil]
  end

  private def mapped_name(name)
    hangar_xplor_mapping[name].presence ||
      starship_42_mapping[name].presence ||
      legacy_mapping[name].presence ||
      name
  end

  private def stop_requested?(index)
    return false unless (index % CANCEL_CHECK_INTERVAL).zero?

    @import.cancel_requested?
  end

  private def legacy_mapping
    {
      "Ursa Rover" => "Ursa",
      "Ursa Rover Fortuna" => "Ursa Fortuna",
      "Retaliator Bomber" => "Retaliator",
      "F7A Hornet" => "F7A Hornet Mk I",
      "F7C Hornet" => "F7C Hornet Mk I",
      "F7C Hornet Wildfire" => "F7C Hornet Wildfire Mk I",
      "F7C-M Super Hornet" => "F7C-M Super Hornet Mk I",
      "F7C-M Super Hornet Heartseeker" => "F7C-M Super Hornet Heartseeker Mk I",
      "F7C-R Hornet Tracker" => "F7C-R Hornet Tracker Mk I",
      "F7C-S Hornet Ghost" => "F7C-S Hornet Ghost Mk I",
      "F8C" => "F8C Lightning",
      "F8C Lightning Executive-Edition" => "F8C Lightning Executive Edition"
    }
  end

  private def legacy_module_mapping
    {
      "Retaliator Bomber" => ["Front Torpedo Bay", "Rear Torpedo Bay"]
    }
  end

  private def starship_42_mapping
    {
      "x1" => "X1",
      "315p explorer" => "315p",
      "325a fighter" => "325a",
      "350r racer" => "350r",
      "600i exploration module" => "600i Explorer",
      "600i touring module" => "600i Touring",
      "caterpillar 2949 best in show" => "Caterpillar",
      "cutlass 2949 best in show" => "Cutlass Black",
      "f7a military hornet" => "F7a Hornet Mk I",
      "f7c hornet" => "F7C Hornet Mk I",
      "f7c hornet wildfire" => "F7C Hornet Wildfire Mk I",
      "f7c-r hornet tracker" => "F7C-R Hornet Tracker Mk I",
      "f7c-s hornet ghost" => "F7C-S Hornet Ghost Mk I",
      "f7c-m super hornet" => "F7C-M Super Hornet Mk I",
      "f7c-m super hornet heartseeker" => "F7C-M Super Hornet Mk I",
      "f8c lightning civilian" => "F8C lightning",
      "hammerhead 2949 best in show" => "Hammerhead",
      "hercules starlifter a2" => "A2 Hercules",
      "hercules starlifter c2" => "C2 Hercules",
      "hercules starlifter m2" => "M2 Hercules",
      "mercury star runner" => "Mercury",
      "mustang omega : amd edition" => "Mustang Omega",
      "nova tank" => "Nova",
      "p-72 archimedes" => "P-72 Archimedes",
      "p-72 archimedes emerald" => "P-72 Archimedes Emerald",
      "pisces - expedition" => "C8X Pisces Expedition",
      "reclaimer 2949 best in show" => "Reclaimer",
      "reliant kore - mini hauler" => "Reliant Kore",
      "reliant mako - news van" => "Reliant Mako",
      "reliant sen - researcher" => "Reliant Sen",
      "reliant tana - skirmisher" => "Reliant Tana",
      "c1 spirit" => "C1 Spirit",
      "e1 spirit" => "E1 Spirit",
      "a1 spirit" => "A1 Spirit",
      "crusader mercury star runner" => "Mercury",
      "genesis starliner" => "Genesis",
      "retaliator base" => "Retaliator",
      "retaliator bomber" => "Retaliator",
      "ursa rover" => "Ursa",
      "ursa rover fortuna" => "Ursa Fortuna"
    }
  end

  private def hangar_xplor_mapping
    {
      "X1 Base" => "X1",
      "315p Explorer" => "315p",
      "325a Fighter" => "325a",
      "350r Racer" => "350r",
      "600i" => "600i Explorer",
      "600i Exploration Module" => "600i Explorer",
      "600i Touring Module" => "600i Touring",
      "Mercury Star Runner" => "Mercury",
      "Captured Vanduul Scythe" => "Scythe",
      "Caterpillar 2949 Best in Show" => "Caterpillar",
      "Cutlass 2949 Best In Show" => "Cutlass Black",
      "Dragonfly" => "Dragonfly Black",
      "F8C Lightning Civilian" => "F8C Lightning",
      "Hammerhead 2949 Best in Show" => "Hammerhead",
      "Hammerhead Best In Show Edition" => "Hammerhead",
      "Hercules Starlifter A2" => "A2 Hercules",
      "Hercules Starlifter C2" => "C2 Hercules",
      "Hercules Starlifter M2" => "M2 Hercules",
      "Genesis Starliner" => "Genesis",
      "Caterpillar Best In Show Edition" => "Caterpillar",
      "Cutlass Black Best In Show Edition" => "Cutlass Black",
      "F7C Hornet" => "F7C Hornet Mk I",
      "F7C-M Super Hornet Heartseeker" => "F7C-M Super Hornet Mk I",
      "F7A Hornet" => "F7A Hornet Mk I",
      "F7C Hornet Wildfire" => "F7C Hornet Wildfire Mk I",
      "F7C-M Super Hornet" => "F7C-M Super Hornet Mk I",
      "F7C-R Hornet Tracker" => "F7C-R Hornet Tracker Mk I",
      "F7C-S Hornet Ghost" => "F7C-S Hornet Ghost Mk I",
      "Hornet F7C" => "F7C Hornet Mk I",
      "Hornet F7C-M Heartseeker" => "F7C-M Super Hornet Mk I",
      "Idris-M Frigate" => "Idris-M",
      "Idris-P Frigate" => "Idris-P",
      "Idris-K Frigate" => "Idris-P",
      "Greycat PTV" => "PTV",
      "GRIN ROC DS" => "ROC DS",
      "Greycat Industrial - ROC" => "ROC",
      "Gatac Railen" => "Railen",
      "Carrack Expedition with Pisces Expedition" => "Carrack Expedition",
      "Carrack with Pisces Expedition" => "Carrack",
      "Carrack w/C8X" => "Carrack",
      "Carrack Expedition w/C8X" => "Carrack Expedition",
      "Dragonfly Star Kitten" => "Dragonfly Starkitten Edition",
      "Mustang Omega : AMD Edition" => "Mustang Omega",
      "Nova Tank" => "Nova",
      "Pisces" => "C8 Pisces",
      "Pisces - Expedition" => "C8X Pisces Expedition",
      "Reclaimer 2949 Best in Show" => "Reclaimer",
      "Reclaimer Best In Show Edition" => "Reclaimer",
      "Reliant Kore - Mini Hauler" => "Reliant Kore",
      "Reliant Mako - News Van" => "Reliant Mako",
      "Reliant Sen - Researcher" => "Reliant Sen",
      "Reliant Tana - Skirmisher" => "Reliant Tana",
      "Rover" => "G12a",
      "Retaliator Base" => "Retaliator",
      "Retaliator Bomber" => "Retaliator",
      "Ursa Rover" => "Ursa",
      "Ursa Rover Fortuna" => "Ursa Fortuna",
      "Argo Mole - Carbon Edition" => "Mole Carbon Edition",
      "Argo Mole - Talus Edition" => "Mole Talus Edition",
      "Crusader A1 Spirit" => "A1 Spirit",
      "Crusader C1 Spirit" => "C1 Spirit",
      "Crusader E1 Spirit" => "E1 Spirit",
      "MOLE - Carbon Edition" => "Carbon",
      "MOLE - Talus Edition" => "Talus",
      "Gladius Dunlevy" => "Dunlevy"
    }
  end

  private def normalize(name)
    transform_to_slug(strip_name(name))
  end

  private def transform_to_slug(name)
    return if name.blank?

    slug = name.parameterize

    slug.presence || name
  end

  private def strip_name(name)
    return if name.blank?

    name.gsub(/(?:AEGIS|Aegis|ARGO|argo|Argo|ANVIL|Anvil|BANU|Banu|Crusader|CRUSADER|crusader|DRAKE|Drake|ESPERIA|Esperia|KRUGER|Kruger|Kruger Intergalactic|MISC|ORIGIN|Origin|RSI|TUMBRIL|Tumbril|VANDUUL|Vanduul|Xi'an|Consolidated Outland|consolidated outland|frigate|Aopoa)/, "").strip
  end
end
