# frozen_string_literal: true

module Models
  # The ships the RSI ship matrix does not list, and the manufacturers they need.
  #
  # Kept as data in one place because two callers want it: `db/seeds` for a fresh
  # database, and Maintenance::SeedManualModelsTask for one that already exists
  # and is missing them.
  module ManualRecords
    MANUFACTURERS = [
      {name: "Origin Jumpworks", slug: "origin-jumpworks", code: "ORIG"},
      {name: "Drake Interplanetary", slug: "drake-interplanetary", code: "DRAK"},
      {
        name: "Musashi Industrial & Starflight Concern",
        slug: "musashi-industrial-starflight-concern",
        code: "MISC"
      }
    ].freeze

    # Base models come first so a straight run creates them before the editions
    # that point at them. `base_model` is resolved by name rather than position,
    # so an out-of-order run still works.
    MODELS = [
      {
        name: "600i Explorer",
        manufacturer: "Origin Jumpworks",
        classification: "exploration",
        production_status: "flight-ready",
        size: "large"
      },
      {
        name: "Dragonfly Black",
        manufacturer: "Drake Interplanetary",
        classification: "competition",
        production_status: "flight-ready",
        size: "vehicle"
      },
      {
        name: "600i Executive-Edition",
        manufacturer: "Origin Jumpworks",
        rsi_name: "600i Executive Edition",
        classification: "exploration",
        production_status: "flight-ready",
        size: "large",
        base_model: "600i Explorer"
      },
      {
        name: "Dragonfly Starkitten Edition",
        manufacturer: "Drake Interplanetary",
        rsi_name: "Dragonfly Star Kitten Edition",
        classification: "competition",
        production_status: "flight-ready",
        size: "vehicle",
        base_model: "Dragonfly Black"
      },
      {
        name: "Raptor",
        manufacturer: "Musashi Industrial & Starflight Concern",
        hidden: true
      }
    ].freeze

    # Everything else in a definition is a plain Model column. Listed so a typo in
    # a definition raises here instead of being assigned to nothing.
    ATTRIBUTES = %i[rsi_name classification production_status size hidden].freeze

    def self.call
      MODELS.each { |definition| upsert_model(definition) }
    end

    # Only ever fills in what is missing: a model somebody has since corrected by
    # hand keeps its values, because `find_or_create_by!` only yields the block
    # for a row it is about to create.
    def self.upsert_model(definition)
      Model.find_or_create_by!(name: definition[:name]) do |model|
        model.manufacturer = upsert_manufacturer(definition[:manufacturer])

        ATTRIBUTES.each do |attribute|
          model.public_send(:"#{attribute}=", definition[attribute]) if definition.key?(attribute)
        end

        model.base_model_id = base_model_for(definition[:base_model])&.id if definition[:base_model].present?
      end
    end

    def self.upsert_manufacturer(name)
      definition = MANUFACTURERS.find { |manufacturer| manufacturer[:name] == name }

      raise ArgumentError, "no manual manufacturer named #{name.inspect}" if definition.nil?

      Manufacturer.find_or_create_by!(name: definition[:name]) do |manufacturer|
        manufacturer.slug = definition[:slug]
        manufacturer.code = definition[:code]
      end
    end

    # Created on demand rather than assumed present, so processing the editions
    # before their base model leaves a link rather than a nil.
    def self.base_model_for(name)
      existing = Model.find_by(name:)

      return existing if existing.present?

      definition = MODELS.find { |model| model[:name] == name }

      raise ArgumentError, "no manual model named #{name.inspect}" if definition.nil?

      upsert_model(definition)
    end
  end
end
