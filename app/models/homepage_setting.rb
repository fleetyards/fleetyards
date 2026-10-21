# frozen_string_literal: true

# What the team curates on the homepage: the ships it takes turns to feature.
# One row; `current` hands it out, unsaved until an admin saves it.
#
# Nobody curating is the usual case, so an empty list draws from every ship
# with a coloured angled render -- the picture the hero is built around --
# unless the feature is switched off altogether.
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

  # The ship of the day: drawn once per day and the same for every visitor,
  # so the homepage reads as one site rather than a slot machine. Seeded by
  # the day, so nothing has to be stored or expired.
  #
  # Drawn: one of the chosen ships, never anything else -- the centred hero is
  # the switch's job. Not drawn: the first ship of the list, in the order it
  # was set.
  def featured_ship(day: Time.zone.today)
    return if featured_hidden

    random = Random.new(day.jd)
    return any_rendered_ship(random) if featured_model_ids.empty?

    ships = featured_models.index_by(&:id).values_at(*featured_model_ids).compact
    return if ships.empty?
    return ships.first unless featured_random

    ships.sample(random:)
  end

  # Sorted before the draw, so the same day draws the same ship however the
  # database happens to return the rows.
  private def any_rendered_ship(random)
    ids = Model.visible.active
      .joins(:angled_view_colored_attachment)
      .order(:id)
      .pluck(:id)
    return if ids.empty?

    Model.find(ids.sample(random:))
  end

  private def normalize_featured_model_ids
    self.featured_model_ids = Array(featured_model_ids).compact_blank.uniq
  end
end
