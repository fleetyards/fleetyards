# frozen_string_literal: true

# Existing hangars are left alone, as when a snub craft is added in admin: a
# Centaurus picks up its Skylark the next time it is saved or synced.
class AddSkylarkSnubToConstellationMkV < ActiveRecord::Migration[8.1]
  def up
    constellation = Model.find_by(slug: "rsi-constellation-mk-v-centaurus")
    skylark = Model.find_by(slug: "rsi-skylark")
    return if constellation.blank? || skylark.blank?

    ModelSnubCraft.find_or_create_by!(model: constellation, snub_craft: skylark)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
