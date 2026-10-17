# frozen_string_literal: true

module BuybackPledges
  # The ship names stored buy-backs give that `BuybackPledge.obtaining_model`
  # matches to no model, with how many pledges carry each. RSI names a ship
  # differently from one pledge page to the next, and a name missing here
  # belongs in `Rsi::ShipNames::MAPPING`.
  class UnmatchedShipNames
    # "Cutlass Black and 2 items" or "ATLS GEO and Lifetime Insurance" names
    # its first ship; "2 ships and 4 items" names none.
    FIRST_SHIP = /\s+and\s+(\d+\s|lifetime\s+insurance).*\z/i
    COUNTED = /\A\d+\s+(ships?|items?)\b/i

    def run
      known = Model.pluck(:name, :rsi_name).flat_map { |names| Rsi::ShipNames.aliases(names) }.to_set

      names.reject { |name| known.include?(name.downcase) }
        .tally
        .sort_by { |name, count| [-count, name] }
    end

    private def names
      listed = BuybackPledge.where.not(ship_names: nil).pluck(:ship_names).flatten
      contained = BuybackPledge.where(kind: "ship", upgraded: false).where.not(contained: nil).pluck(:contained)
        .map { |value| value.sub(FIRST_SHIP, "") }
        .grep_v(COUNTED)

      (listed + contained).filter_map { |name| name.squish.presence }
    end
  end
end
