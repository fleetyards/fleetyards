# frozen_string_literal: true

module ScData
  # Which manufacturer a game-file identifier belongs to.
  #
  # Nothing in the export says. The parsed model record carries a name, a
  # description, a career and a role, but no manufacturer -- and
  # `belongs_to :manufacturer` on Model is required, so anything that creates a
  # model from the game files needs this first.
  #
  # The identifier's prefix is the signal: `drak_caterpillar` is Drake. Both
  # tables below were derived from the 215 models already matched to a parsed
  # file rather than from a reading of the naming scheme, so they are evidence.
  # Only 20 prefixes exist across the whole catalogue.
  class ManufacturerMapping
    # Eighteen resolve on the prefix alone. Two of them do not spell their own
    # code: Aopoa files under `xian`, Grey's Market under `glsn`.
    PREFIXES = {
      "aegs" => "AEGS", "anvl" => "ANVL", "argo" => "ARGO", "banu" => "BANU",
      "cnou" => "CNOU", "crus" => "CRUS", "drak" => "DRAK", "espr" => "ESPR",
      "gama" => "GAMA", "glsn" => "GREY", "grin" => "GRIN", "krig" => "KRIG",
      "mrai" => "MRAI", "misc" => "MISC", "orig" => "ORIG", "rsi" => "RSI",
      "tmbl" => "TMBL", "vncl" => "VNCL", "xian" => "XNAA", "xnaa" => "XNAA"
    }.freeze

    # Where the prefix names the wrong company, because the export files a ship
    # under the parent brand or under what the ship is a copy of.
    #
    # Mirai is MISC's sub-brand, so the Fury and the Razor ship as `misc_*`.
    # Esperia builds replicas of Vanduul hulls, so the Blade, Glaive and Stinger
    # ship as `vncl_*` -- while the Scythe under the same prefix really is
    # Vanduul.
    #
    # Matched on the stem, so `misc_fury_lx` and `misc_fury_miru` both resolve
    # through `misc_fury`. No stem may be a prefix of another -- a test pins
    # that, because two overlapping stems would need an order this does not
    # define.
    FAMILIES = {
      "misc_fury" => "MRAI",
      "misc_razor" => "MRAI",
      "vncl_blade" => "ESPR",
      "vncl_glaive" => "ESPR",
      "vncl_stinger" => "ESPR"
    }.freeze

    # The manufacturer code, or nil for a prefix nothing in the catalogue has
    # used yet. Nil is a finding rather than a failure: it means the export has
    # introduced a company, which is worth reporting rather than guessing at.
    def self.code_for(identifier)
      identifier = identifier.to_s.downcase
      return if identifier.blank?

      family = FAMILIES.keys.find { |stem| identifier == stem || identifier.start_with?("#{stem}_") }
      return FAMILIES.fetch(family) if family

      PREFIXES[identifier.split("_").first]
    end

    # The manufacturer itself, when we already have it. A code the export names
    # and the catalogue does not carry resolves to nil for the same reason.
    def self.for(identifier)
      code = code_for(identifier)

      Manufacturer.find_by(code:) if code.present?
    end

    def self.known_prefix?(identifier)
      code_for(identifier).present?
    end
  end
end
