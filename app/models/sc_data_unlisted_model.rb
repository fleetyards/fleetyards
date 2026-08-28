# frozen_string_literal: true

# A ship the game files describe that Fleetyards has no model for.
#
# See the migration for why these exist at all. The short version: the RSI ship
# matrix is the only thing that creates a `Model`, so anything in the game and
# not on the matrix is invisible, and until now nothing said so.
class ScDataUnlistedModel < ApplicationRecord
  # The ship it appears to be a variant of, where the identifier extends one we
  # already carry.
  belongs_to :base_model, class_name: "Model", optional: true

  # Set once a decision turns into a model.
  belongs_to :model, optional: true

  # How the export's version compares to that base ship. Descriptive rather than
  # a verdict: the game files never say whether a player can own something, and
  # that is the only question the catalogue cares about. An in-game-only
  # collector version and a mission prop can be mechanically identical.
  COMPARISONS = %w[identical refitted structural unrelated].freeze

  # `ignored` covers everything that is not a ship somebody owns -- NPC copies
  # the marker filter missed, props, templates. `paint` means it belongs on an
  # existing model as a livery instead.
  DECISIONS = %w[ignored model paint].freeze

  validates :identifier, presence: true, uniqueness: true
  validates :comparison, inclusion: {in: COMPARISONS}, allow_nil: true
  validates :decision, inclusion: {in: DECISIONS}, allow_nil: true

  scope :undecided, -> { where(decision: nil) }
  scope :decided, -> { where.not(decision: nil) }

  # Everything this build showed for the first time, which is what a person
  # actually wants to see -- as opposed to the pile that has been sitting
  # undecided since the table was created.
  scope :first_seen_in, ->(source = ::ScData::Source.current) {
    where(first_seen_environment: source.environment, first_seen_version: source.version)
  }

  # The export named a prefix no ship in the catalogue uses. Either a new
  # company, or the file is not a ship -- every unresolved identifier in the live
  # tree today is a world object.
  def unknown_manufacturer?
    manufacturer_code.blank?
  end

  def manufacturer
    Manufacturer.find_by(code: manufacturer_code) if manufacturer_code.present?
  end

  # Turns the entry into a real model. The export gives a name; the identifier
  # gives a manufacturer, which `belongs_to :manufacturer` requires. Nothing else
  # is guessed -- the next sc_data load fills in the mechanics and flips
  # `in_game`, because a parsed file exists for it by definition.
  #
  # Created hidden, which is the column default: an admin still has to give it
  # images, a classification and a production status before it belongs in the
  # public catalogue.
  def create_model!
    raise ArgumentError, "already decided" if decision.present?
    raise ArgumentError, "no manufacturer for #{identifier}" if manufacturer.blank?

    transaction do
      created = Model.create!(name: name.presence || identifier, manufacturer:, sc_key: identifier)

      update!(decision: "model", model: created, decided_at: Time.current)

      created
    end
  end

  def decide!(decision)
    update!(decision:, decided_at: Time.current)
  end

  def mark_as_paint!
    decide!("paint")
  end

  # Back to undecided, for a decision made in error. The model a `create_model`
  # left behind is not deleted here -- deleting a ship is its own action, and a
  # hangar entry may already point at it.
  def reset!
    update!(decision: nil, model: nil, decided_at: nil)
  end

  DEFAULT_SORTING_PARAMS = ["identifier asc"]
  ALLOWED_SORTING_PARAMS = [
    "identifier asc", "identifier desc",
    "name asc", "name desc",
    "comparison asc", "comparison desc",
    "firstSeenVersion asc", "firstSeenVersion desc",
    "createdAt asc", "createdAt desc"
  ]

  def self.ransackable_attributes(_auth_object = nil)
    %w[id identifier name comparison decision manufacturer_code first_seen_version
      last_seen_version created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[base_model model]
  end
end
