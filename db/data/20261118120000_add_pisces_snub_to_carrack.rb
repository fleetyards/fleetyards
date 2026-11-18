# frozen_string_literal: true

# The Carrack Expedition pledge imports as the Carrack, so the plain C8 Pisces
# stands in for the C8X. Existing hangars pick it up on their next save or sync.
class AddPiscesSnubToCarrack < ActiveRecord::Migration[8.1]
  def up
    carrack = Model.find_by(slug: "anvl-carrack")
    pisces = Model.find_by(slug: "anvl-c8-pisces")
    return if carrack.blank? || pisces.blank?

    ModelSnubCraft.find_or_create_by!(model: carrack, snub_craft: pisces)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
