# frozen_string_literal: true

# What the team curates on the homepage: the ships it takes turns to feature.
# One row; `current` hands it out, unsaved until an admin saves it.
class HomepageSetting < ApplicationRecord
  MAX_FEATURED_MODELS = 20

  before_validation :normalize_featured_model_ids

  validates :featured_model_ids, length: {maximum: MAX_FEATURED_MODELS}

  def self.current
    first || new
  end

  # The ships that can be featured right now: a deleted, hidden or retired one
  # stays in the list until an admin saves it again, but is never shown.
  def featured_models
    return Model.none if featured_model_ids.empty?

    Model.visible.active.where(id: featured_model_ids)
  end

  # Drawn: a different one each visit -- or none, as one more entry in the
  # draw, so the centred hero still turns up now and then. Not drawn: the
  # first ship of the list, in the order it was set.
  def featured_ship(random: Random)
    ships = featured_models.index_by(&:id).values_at(*featured_model_ids).compact
    return if ships.empty?
    return ships.first unless featured_random

    [*ships, nil].sample(random:)
  end

  private def normalize_featured_model_ids
    self.featured_model_ids = Array(featured_model_ids).compact_blank.uniq
  end
end
