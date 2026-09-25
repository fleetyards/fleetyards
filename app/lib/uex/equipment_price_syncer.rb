# frozen_string_literal: true

module Uex
  class EquipmentPriceSyncer < ItemPriceSyncer
    ITEM_TYPE = "Equipment"

    # The UEX sections that hold what a player wears or carries. Medical pens
    # and tools sit in "Miscellaneous" beside food and drink, so that section
    # is matched but left out of the report: a sandwich we cannot place is not
    # a gap.
    SECTIONS = ["Armor", "Clothing", "Personal Weapons", "Undersuits"].freeze

    private def build_matcher
      Uex::EquipmentMatcher.new
    end

    # Deliberately free of anything that moves on its own. GithubIssueCreator
    # dedupes on a digest of the body, so a line that changes when nothing has
    # actually changed opens a fresh issue every single run -- which is why the
    # counts and the misses outside our sections are absent. Those live in the
    # import output, which nothing dedupes.
    def self.github_issue_body(result)
      lines = ["## Priced UEX Gear We Cannot Place", ""]

      if result.stale_mappings.any?
        lines << "### Mapped to an item that is gone"
        lines << ""
        lines << "`Uex::EquipmentMatcher::MAPPINGS` names an `sc_key` the catalogue no longer"
        lines << "carries, so the price is dropped. The entry needs repointing or removing --"
        lines << "until it is, this item is unpriced and the mapping is doing nothing."
        lines << ""
        result.stale_mappings.each do |row, sc_key|
          lines << "- **#{row["item_name"]}** — UEX item `#{row["id_item"]}` → missing `#{sc_key}`"
        end
        lines << ""
      end

      if result.ambiguous.any?
        lines << "### Named by several items"
        lines << ""
        lines << "Colourways and variants carry a record each, so these names answer to more"
        lines << "than one item and nothing says which one the shop stocks. They are left"
        lines << "unpriced. Add an entry to `Uex::EquipmentMatcher::MAPPINGS` to settle one."
        lines << ""
        result.ambiguous.each do |row, sc_keys|
          lines << "- **#{row["item_name"]}** — UEX item `#{row["id_item"]}` → `#{sc_keys.join("`, `")}`"
        end
        lines << ""
      end

      if result.unknown.any?
        lines << "### Gear we cannot place"
        lines << ""
        lines << "UEX files these under a section a player wears or carries from, and neither"
        lines << "`sc_ref` nor the name reaches an `Equipment` in the build we are on. Either"
        lines << "that build has dropped the item, or a patch renamed it and its prices have"
        lines << "silently gone with the old name."
        lines << ""
        result.unknown.each do |row|
          lines << "- **#{row["item_name"]}** — UEX item `#{row["id_item"]}`"
        end
      end

      lines.join("\n")
    end
  end
end
