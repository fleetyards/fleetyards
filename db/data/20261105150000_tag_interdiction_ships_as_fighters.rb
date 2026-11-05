# frozen_string_literal: true

# The ship matrix and the game files word these ships as "Interdiction" alone,
# though each is a fighter fitted for it, so a slot asking for fighters never
# offered them. Each takes the size of fighter its own hull family or weapons
# make it. The keys differ from what the wording maps to from here on, which is
# how the loaders recognise keys picked by hand and leave them alone.
class TagInterdictionShipsAsFighters < ActiveRecord::Migration[8.1]
  FIGHTER_KEYS = {
    "mrai-guardian-qi" => "heavy_fighter",
    "aegs-avenger-warlock" => "light_fighter",
    "aegs-sabre-raven" => "medium_fighter",
    "drak-cutlass-blue" => "medium_fighter",
    "rsi-mantis" => "light_fighter"
  }.freeze

  def up
    FIGHTER_KEYS.each do |slug, key|
      row = select_one("SELECT id, array_to_json(foci) AS foci FROM models WHERE slug = #{connection.quote(slug)}")
      next if row.nil?

      keys = ::Model.normalize_value_for(:foci, JSON.parse(row["foci"]) + [key])
      focus = I18n.with_locale(:en) { ::Model.focus_labels(keys).join(" / ") }.presence
      array = keys.map { |entry| connection.quote(entry) }.join(", ")

      execute <<~SQL.squish
        UPDATE models
        SET foci = ARRAY[#{array}]::varchar[], focus = #{connection.quote(focus)}, updated_at = NOW()
        WHERE id = #{connection.quote(row["id"])}
      SQL
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
