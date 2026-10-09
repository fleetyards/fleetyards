# frozen_string_literal: true

# A ship linked to its game file before linking claimed the identifier still
# reads the file its slug names: nothing at all for the Basher, the S-65
# Stingray and the ATLS IKTI Akuma, and a template with an older loadout for
# the Hammerhead. Each takes the identifier it was linked to, unless someone set
# one by hand, and its game data is loaded again.
class ClaimLinkedScKeys < ActiveRecord::Migration[8.1]
  def up
    claimed = []
    links = ScDataUnlistedModel.where(decision: "model").where.not(model_id: nil)
    # A ship several files are linked to is left for a person: which of them is
    # the ship, and which a variant, is not something to guess.
    ambiguous = links.group(:model_id).having("COUNT(*) > 1").pluck(:model_id)

    links.where.not(model_id: ambiguous).find_each do |entry|
      model = Model.find_by(id: entry.model_id)
      next if model.blank? || model.sc_key.present?

      Model.where(id: model.id).update_all(sc_key: entry.identifier, updated_at: Time.current)
      ScDataUnlistedModel.where(id: entry.id).update_all(claimed_sc_key: true)
      claimed << model.id
    end

    # Delayed past the migration's transaction, or the job could read the old key.
    claimed.each { |id| Loaders::ScData::ModelJob.perform_in(1.minute, id) }
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
