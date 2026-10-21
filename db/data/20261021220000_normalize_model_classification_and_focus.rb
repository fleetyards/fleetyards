# frozen_string_literal: true

# The ship matrix's own spellings of a classification -- "Combat", "Multi-Role"
# -- sat beside ours, so every filter listed them twice. A focus carried
# trailing spaces and a handful of spellings of one word. `Model` normalises
# both from here on; this brings the rows it already holds in line.
#
# A crew slot asks for a classification by the same words, so a slot asking
# for "Combat" matched only the five ships spelled that way.
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

  def up
    classification = "lower(btrim(classification))"
    aliases = CLASSIFICATION_ALIASES.map { |from, to| "WHEN #{quote(from)} THEN #{quote(to)}" }.join(" ")
    normalized = "NULLIF(CASE #{classification} #{aliases} ELSE #{classification} END, '')"

    %w[models fleet_event_ships mission_ships].each do |table|
      touch = (table == "models") ? ", updated_at = NOW()" : ""

      execute <<~SQL.squish
        UPDATE #{table} SET classification = #{normalized}#{touch}
        WHERE classification IS DISTINCT FROM #{normalized}
      SQL
    end

    focus = FOCUS_SPELLINGS.reduce("NULLIF(regexp_replace(btrim(focus), '\\s+', ' ', 'g'), '')") do |sql, (from, to)|
      "regexp_replace(#{sql}, #{quote("\\m#{from}\\M")}, #{quote(to)}, 'gi')"
    end

    execute <<~SQL.squish
      UPDATE models SET focus = #{focus}, updated_at = NOW()
      WHERE focus IS DISTINCT FROM #{focus}
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private def quote(value)
    connection.quote(value)
  end
end
