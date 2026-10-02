# frozen_string_literal: true

module Rsi
  # The activities and commitment levels an RSI organisation can pick, keyed by
  # our slug, with the name RSI prints for them on the org page and in its org
  # search.
  module OrgAttributes
    ACTIVITIES = {
      "bounty_hunting" => "Bounty Hunting",
      "engineering" => "Engineering",
      "exploration" => "Exploration",
      "freelancing" => "Freelancing",
      "infiltration" => "Infiltration",
      "medical" => "Medical",
      "piracy" => "Piracy",
      "resources" => "Resources",
      "scouting" => "Scouting",
      "security" => "Security",
      "smuggling" => "Smuggling",
      "social" => "Social",
      "trading" => "Trading",
      "transport" => "Transport"
    }.freeze

    COMMITMENTS = {
      "casual" => "Casual",
      "regular" => "Regular",
      "hardcore" => "Hardcore"
    }.freeze

    def self.activity_for(name)
      lookup(ACTIVITIES, name)
    end

    def self.commitment_for(name)
      lookup(COMMITMENTS, name)
    end

    private_class_method def self.lookup(values, name)
      values.find { |_slug, label| label.casecmp?(name.to_s.strip) }&.first
    end
  end
end
