# frozen_string_literal: true

module Uex
  class ComponentPriceSyncer < ItemPriceSyncer
    ITEM_TYPE = "Component"

    # The UEX sections that hold things a ship carries. Everything else it
    # prices -- clothing, food, FPS weapons, helmets -- is not a component and
    # never will be, so an unmatched item from one of those is noise rather than
    # a gap. Nineteen of UEX's twenty-four thousand price rows in the other
    # sections would otherwise drown the one report that matters.
    SECTIONS = [
      "Vehicle Weapons", "Systems", "Utility", "Propulsion", "Avionics", "Module", "Liveries"
    ].freeze

    private def build_matcher
      Uex::ComponentMatcher.new
    end

    # Deliberately free of anything that moves on its own. GithubIssueCreator
    # dedupes on a digest of the body, so a line that changes when nothing has
    # actually changed opens a fresh issue every single run -- which is why the
    # counts are absent, and why the personal-gear misses are absent too: UEX
    # adds a pair of trousers most weeks and not one of them is a component.
    # Those live in the import output, which nothing dedupes.
    def self.github_issue_body(result)
      lines = ["## Priced UEX Items We Cannot Place", ""]

      if result.stale_mappings.any?
        lines << "### Mapped to a component that is gone"
        lines << ""
        lines << "`Uex::ComponentMatcher::MAPPINGS` names an `sc_key` the catalogue no longer"
        lines << "carries, so the price is dropped. The entry needs repointing or removing --"
        lines << "until it is, this item is unpriced and the mapping is doing nothing."
        lines << ""
        result.stale_mappings.each do |row, sc_key|
          lines << "- **#{row["item_name"]}** — UEX item `#{row["id_item"]}` → missing `#{sc_key}`"
        end
        lines << ""
      end

      if result.ambiguous.any?
        lines << "### Named by several components"
        lines << ""
        lines << "The game files carry a row per mount, so these names answer to more than one"
        lines << "component and nothing says which one the shop stocks. They are left unpriced:"
        lines << "guessing would put a shop price on a mount welded to one ship. Add an entry to"
        lines << "`Uex::ComponentMatcher::MAPPINGS` to settle one."
        lines << ""
        result.ambiguous.each do |row, sc_keys|
          lines << "- **#{row["item_name"]}** — UEX item `#{row["id_item"]}` → `#{sc_keys.join("`, `")}`"
        end
        lines << ""
      end

      if result.unknown.any?
        lines << "### A ship part we cannot place"
        lines << ""
        lines << "UEX files these under a section a ship carries from, and neither `sc_ref` nor"
        lines << "the name reaches a catalogued `Component`. Either the build we are on has"
        lines << "dropped the part, or a patch renamed it and its prices have silently gone with"
        lines << "the old name."
        lines << ""
        result.unknown.each do |row|
          lines << "- **#{row["item_name"]}** — UEX item `#{row["id_item"]}`"
        end
      end

      lines.join("\n")
    end
  end
end
