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

  # `ignored` is for anything the catalogue should not carry, whatever the
  # reason -- an NPC copy the marker filter missed, a prop, a template, or a ship
  # that simply does not belong in it. `paint` means it belongs on an existing
  # model as a livery instead.
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

  # The name to give a model made from this entry. The export prefixes the
  # manufacturer and Fleetyards does not -- it ships "Esperia Prowler" and
  # "Argo MOLE" where the catalogue says "Prowler" and "MOLE". Taking the export
  # name as-is would both break the convention and slip past Model's name
  # uniqueness, which is scoped to the manufacturer.
  def suggested_name
    export_name = name.presence || identifier
    return export_name if manufacturer.blank?

    prefixes = manufacturer.name_prefixes

    prefixes.each do |prefix|
      stripped = export_name.sub(/\A#{Regexp.escape(prefix)}\s+/i, "")

      return stripped if stripped != export_name
    end

    export_name
  end

  # A ship of that name already in the catalogue. Only 64 of 247 models carry an
  # `sc_key`, so an existing ship whose identifier is derived from its slug never
  # matches a game-file identifier and lands in this list anyway -- this is what
  # stops a second one being made from it.
  def existing_model
    return if manufacturer.blank?

    Model.find_by(manufacturer:, name: suggested_name)
  end

  # A livery of that name already on the ship this extends. Nine entries in the
  # live tree have one -- Dunlevy, Heartseeker, Carrack Expedition, Snowblind --
  # so the work is already done and the entry only needs marking.
  def existing_paint
    return if base_model.blank?

    token = identifier.sub("#{base_model.sc_data_identifier}_", "").split("_").first
    return if token.blank? || token == identifier

    base_model.paints.find { |paint| paint.name.to_s.downcase.include?(token.downcase) }
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

    # Refused rather than silently duplicated: an existing ship of this name
    # means the entry is a variant, a livery, or the same ship under a slug the
    # game files spell differently. Which of those it is, only a person knows.
    existing = existing_model
    raise ArgumentError, "#{existing.name} already exists" if existing.present?

    transaction do
      created = Model.create!(name: suggested_name, manufacturer:, sc_key: identifier)

      update!(decision: "model", model: created, decided_at: Time.current)

      created
    end
  end

  # The catalogue already has this ship, under an identifier the game files spell
  # differently. Records which one, so the entry stops being reported and the
  # answer is kept rather than being worked out again next patch.
  #
  # A link says this file *is* the ship, so the ship takes its identifier when
  # it has none of its own. Left on the slug-derived one it reads whatever file
  # that happens to name: nothing for the Basher, and for the Hammerhead a
  # template with an older loadout. A variant belongs under `paint` or
  # `ignored`, not here. An `sc_key` someone already set is theirs to change.
  #
  # Answers whether the ship's identifier changed, which is when its game data
  # has to be loaded again.
  def link_to_model!(target)
    raise ArgumentError, "already decided" if decision.present?
    raise ArgumentError, "no model given" if target.blank?

    transaction do
      update!(decision: "model", model: target, decided_at: Time.current)

      next false if target.sc_key.present?

      target.update!(sc_key: identifier)
      update!(claimed_sc_key: true)
      true
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
  #
  # A ship hands back the identifier a link gave it, or it keeps reading the
  # wrong file. Only one the link wrote: a key someone set by hand, or the one a
  # `create_model` made the ship with, is the ship's own.
  #
  # Answers the ship whose identifier changed, if any.
  def reset!
    released = model if claimed_sc_key && model.present? && model.sc_key == identifier

    transaction do
      update!(decision: nil, model: nil, decided_at: nil, claimed_sc_key: false)
      released&.update!(sc_key: nil)
    end

    released
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
