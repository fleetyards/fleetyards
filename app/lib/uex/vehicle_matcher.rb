# frozen_string_literal: true

module Uex
  class VehicleMatcher
    # UEX vehicle slug => our Model slug, for the vehicles neither the slug nor
    # either name form resolves. Maintained by hand, same as the mapping hashes
    # in Rsi::LoanerLoader and ModulesImporter.
    MAPPINGS = {
      "a2-hercules-starlifter" => "crus-a2-hercules",
      "c2-hercules-starlifter" => "crus-c2-hercules",
      "m2-hercules-starlifter" => "crus-m2-hercules",
      "ares-inferno-starfighter" => "crus-ares-inferno",
      "ares-ion-starfighter" => "crus-ares-ion",
      "c8r-pisces-rescue" => "anvl-c8r-pisces",
      "nova-tank" => "tmbl-nova",
      "san-tok-y-i" => "xnaa-san-tok-yai"
    }.freeze

    attr_reader :misses

    def initialize
      models = Model.select(:id, :name, :slug).to_a

      @by_slug = models.index_by(&:slug)
      @by_name = models.index_by { |model| model.name.to_s.downcase }
      @misses = []
    end

    def match(vehicle)
      model = lookup(vehicle)

      @misses << vehicle if model.blank?

      model
    end

    private def lookup(vehicle)
      mapped = MAPPINGS[vehicle["slug"]]

      # The hand-written mapping is an override: it wins over the generic
      # strategies so a wrong name collision can always be corrected.
      return @by_slug[mapped] if mapped.present?

      @by_slug[vehicle["slug"]] ||
        @by_name[vehicle["name"].to_s.downcase] ||
        @by_name[vehicle["name_full"].to_s.downcase]
    end
  end
end
