# frozen_string_literal: true

module Rsi
  # Reads the two ships an RSI upgrade (CCU) title names, such as
  # "Upgrade - Cutlass Black to Carrack Warbond Edition", and finds them in the
  # catalogue by name or by RSI's own name for them.
  module UpgradeTitles
    UPGRADE_NAME = /\A(?:Upgrade\s*-\s*)?(.+?)\s+to\s+(.+)\z/i
    SALE_SUFFIX = /\s+(-\s*)?(warbond(\s+edition)?|standard\s+edition|best\s+in\s+show(\s+edition)?(\s+\d{4})?)\z/i

    # The two ship names, downcased, with how the upgrade was sold taken off
    # the target; empty for a title that names no upgrade.
    def self.ship_names(title)
      match = UPGRADE_NAME.match(title.to_s.squish)
      return [] if match.nil?

      [match[1], match[2].sub(SALE_SUFFIX, "")].map { |part| part.strip.downcase }
    end

    # Each downcased name with the model it names, or nil.
    def self.models_by_name(names, preload: [])
      return {} if names.empty?

      aliases = ShipNames::MAPPING.to_h { |rsi_name, name| [rsi_name.downcase, name.downcase] }
      lookup = names.uniq.index_with { |name| aliases.fetch(name, name) }
      found = Model.visible.active.includes(preload)
        .where("lower(models.name) IN (:names) OR lower(models.rsi_name) IN (:names)", names: lookup.values.uniq).to_a

      lookup.transform_values do |name|
        found.find { |model| model.name.downcase == name } || found.find { |model| model.rsi_name&.downcase == name }
      end
    end
  end
end
