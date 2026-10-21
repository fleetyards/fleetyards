# frozen_string_literal: true

# The ship matrix's own spellings of a classification -- "Combat", "Multi-Role"
# -- sat beside ours, so every filter listed them twice. A focus carried
# trailing spaces and a handful of spellings of one word. `Model` normalises
# both from here on; this brings the rows it already holds in line.
#
# A crew slot asks for a classification and a focus by the same words, so a
# slot asking for "Combat" matched only the five ships spelled that way.
class NormalizeModelClassificationAndFocus < ActiveRecord::Migration[8.1]
  CLASSIFICATION_ALIASES = {
    "multi-role" => "multi",
    "starter" => "multi",
    "transporter" => "transport",
    "destroyer" => "combat"
  }.freeze

  # Spellings an admin gave a focus that the rest of the catalogue writes
  # another way.
  FOCUS_SPELLINGS = {
    "Gun Ship" => "Gunship",
    "Interdictor" => "Interdiction",
    "Anti-aircraft" => "Anti-Air",
    "Medium Freighter" => "Medium Freight",
    "Transporter" => "Transport"
  }.freeze

  CLASSIFICATIONS = %w[combat competition exploration ground industrial multi support transport].freeze

  TABLES = %w[models fleet_event_ships mission_ships].freeze

  def up
    classification = "lower(#{trimmed("classification")})"
    # A word that is none of ours would leave the row failing validation on
    # every later save, so it falls through to NULL rather than stays.
    mapping = CLASSIFICATIONS.to_h { |word| [word, word] }.merge(CLASSIFICATION_ALIASES)
    normalized = "CASE #{classification} #{mapping.map { |from, to| "WHEN #{quote(from)} THEN #{quote(to)}" }.join(" ")} END"

    focus = FOCUS_SPELLINGS.reduce("NULLIF(regexp_replace(#{trimmed("focus")}, '\\s+', ' ', 'g'), '')") do |sql, (from, to)|
      "regexp_replace(#{sql}, #{quote("\\m#{from}\\M")}, #{quote(to)}, 'gi')"
    end

    TABLES.each do |table|
      touch = (table == "models") ? ", updated_at = NOW()" : ""

      execute <<~SQL.squish
        UPDATE #{table} SET classification = #{normalized}, focus = #{focus}#{touch}
        WHERE classification IS DISTINCT FROM #{normalized} OR focus IS DISTINCT FROM #{focus}
      SQL
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  # Ruby's strip takes tabs and newlines too; btrim alone takes spaces.
  private def trimmed(column)
    "regexp_replace(#{column}, '^\\s+|\\s+$', '', 'g')"
  end

  private def quote(value)
    connection.quote(value)
  end
end
