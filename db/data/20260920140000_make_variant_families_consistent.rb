# frozen_string_literal: true

# `Model#variants` answers one of two ways: by `base_model_id` when the model
# has one, and by `rsi_chassis_id` when it does not. Both work. What does not
# work is a family where only some members carry a base -- the answer stops
# being symmetric, and which ships appear depends on whose page you are on.
#
# Four families are in that state. The Cyclone RN lists its five siblings, via
# the chassis, and appears on none of their pages, because they ask for models
# sharing a base and the RN has none. The Heartseeker and the A1 Spirit have the
# opposite problem: they carry a base nothing else does, so they show no
# variants at all while their families show them.
#
# The fix is consistency, not a new opinion about what a family is: follow the
# majority. Where one member is missing a base, give it the family's. Where one
# member is the only one carrying a base, take it away and let the chassis
# answer for everybody.
class MakeVariantFamiliesConsistent < ActiveRecord::Migration[8.1]
  # Cutlass Steel and Cyclone RN join their families; the Heartseeker and the A1
  # stop being the only member of theirs with a base.
  LINK = {
    "drak-cutlass-steel" => "drak-cutlass-black",
    "tmbl-cyclone-rn" => "tmbl-cyclone"
  }.freeze

  UNLINK = %w[anvl-f7c-m-super-hornet-heartseeker-mk-i crus-a1-spirit].freeze

  def up
    LINK.each do |slug, base_slug|
      model = Model.find_by(slug: slug)
      base = Model.find_by(slug: base_slug)

      next say("no model for #{slug} or #{base_slug}") if model.nil? || base.nil?
      next say("#{slug} already has a base") if model.base_model_id.present?

      model.update_columns(base_model_id: base.id)
      say("#{slug} -> #{base_slug}")
    end

    UNLINK.each do |slug|
      model = Model.find_by(slug: slug)

      next say("no model for #{slug}") if model.nil?
      next say("#{slug} has no base to clear") if model.base_model_id.blank?

      # Only when it really is the odd one out. If somebody has since given the
      # rest of the family a base, clearing this one would create the very
      # asymmetry the migration is here to remove.
      family = Model.where(rsi_chassis_id: model.rsi_chassis_id).where.not(id: model.id)
      if family.where.not(base_model_id: nil).exists?
        next say("#{slug} is no longer the only one with a base, left alone")
      end

      model.update_columns(base_model_id: nil)
      say("#{slug} -> chassis")
    end
  end

  # Which of the two shapes a family was in is not worth restoring; both answer
  # the same question and only one of them answers it the same way twice.
  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
