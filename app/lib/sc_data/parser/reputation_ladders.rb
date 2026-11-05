module ScData
  module Parser
    # The reputation scopes the export declares, each a ladder of standings.
    # Read by the contracts, which name the ladder an award feeds, and by the
    # factions, which list the ladders a player can climb.
    module ReputationLadders
      SCOPES_PATH = "reputation/scopes"
      LADDER_STANDINGS_PATH = "reputation/standings"

      # Scope ref to its ladder. A scope with no resolved name still has a key:
      # an award feeding one is real, there is just nothing to call it.
      private def reputation_scopes
        @reputation_scopes ||= load_data(SCOPES_PATH).each_with_object({}) do |item, index|
          values = item[:values]
          ref = value_or_nil(values["__ref"])

          next if ref.blank?

          standing_map = values["standingMap"] || {}

          index[ref] = {
            key: item[:key].downcase,
            name: value_or_nil(localize(values["displayName"])),
            ceiling: standing_map["reputationCeiling"]&.to_i,
            ranks: ladder_ranks(standing_map)
          }
        end
      end

      # Lowest first, because the order the scope lists them in is not always
      # the climb. A standing with no resolved name is dropped: 36 of the 41 on
      # the affinity ladder are localisation placeholders.
      private def ladder_ranks(standing_map)
        refs = Array.wrap(standing_map.dig("standings", "Reference")).map { |reference| reference["value"] }

        refs.filter_map { |ref| ladder_standings[ref] }.sort_by { |rank| rank[:min_reputation] }
      end

      private def ladder_standings
        @ladder_standings ||= load_data(LADDER_STANDINGS_PATH).each_with_object({}) do |item, index|
          values = item[:values]
          ref = value_or_nil(values["__ref"])
          name = value_or_nil(localize(values["displayName"]))

          next if ref.blank? || name.blank?

          index[ref] = {name:, min_reputation: values["minReputation"].to_i}
        end
      end
    end
  end
end
