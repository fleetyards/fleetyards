# frozen_string_literal: true

module Models
  # The parts of a ship's focus, as the ship matrix or the game files word it,
  # that `FocusMapping` has no key for. The loaders drop such a part, so a new
  # wording from CIG leaves a ship without the focus it names.
  #
  # Read off the whole catalogue rather than one run, so both loaders report
  # the same list and an unchanged one is not reported twice.
  class UnplacedFoci
    Ship = Data.define(:name, :source, :wording)
    Entry = Data.define(:part, :ships)

    SOURCES = {rsi_focus: "ship matrix", sc_role: "game files"}.freeze

    def self.call
      new.call
    end

    def self.report(record: nil)
      entries = call

      return if entries.empty?

      AdminReport.deliver(
        task_type: "unplaced_foci",
        title: "Focus wording we cannot place (#{entries.size})",
        body: report_body(entries),
        actionable: true,
        link: "/models",
        record:
      )
    end

    def self.report_body(entries)
      lines = [
        "## Focus wording we cannot place (#{entries.size})",
        "",
        "Each part needs a line in `Models::FocusMapping::PARTS` where a key in `Model::FOCI` fits, or a new key with its label in every locale."
      ]

      entries.each do |entry|
        lines += ["", "### #{entry.part}", ""]
        lines += entry.ships.map { |ship| "- **#{ship.name}** (#{ship.source}: \"#{ship.wording}\")" }
      end

      lines.join("\n")
    end

    def call
      ships = Hash.new { |hash, part| hash[part] = [] }

      Model.where.not(rsi_focus: [nil, ""]).or(Model.where.not(sc_role: [nil, ""]))
        .order(:name).pluck(:name, *SOURCES.keys).each do |name, *wordings|
        SOURCES.values.zip(wordings).each do |source, wording|
          next if wording.blank?

          FocusMapping.call(wording).unknown.uniq.each do |part|
            ships[part] << Ship.new(name:, source:, wording:)
          end
        end
      end

      ships.sort.map { |part, list| Entry.new(part:, ships: list) }
    end
  end
end
