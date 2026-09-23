# frozen_string_literal: true

# A record that can be narrowed to one or more of its fleet's squadrons.
#
# The switch is the record's own `visibility`, so the three models that carry
# this keep the vocabulary they already had and gain one value; the assignments
# say which squadrons. Both halves are needed -- a visibility of "squadron"
# naming none would be visible to nobody, which is never what anybody meant.
module SquadronRestrictable
  extend ActiveSupport::Concern

  included do
    has_many :fleet_squadron_assignments, as: :assignable, dependent: :destroy
    has_many :fleet_squadrons, through: :fleet_squadron_assignments

    validate :assigned_squadrons_belong_to_the_fleet
    validate :squadron_visibility_names_a_squadron

    scope :squadron_restricted, -> { where(visibility: squadron_visibility_value) }

    scope :not_squadron_restricted, -> { where.not(visibility: squadron_visibility_value) }

    # The restricted records this membership is inside. Positive on its own so
    # a policy that already composes an `.or` chain can add it as one more
    # branch rather than restating the rest.
    scope :restricted_to_squadrons_of, lambda { |membership|
      next none if membership.blank?

      squadron_restricted.where(
        id: FleetSquadronAssignment
          .where(assignable_type: name)
          .where(fleet_squadron_id: membership.fleet_squadron_ids)
          .select(:assignable_id)
      )
    }

    # Everything squadron access allows: what is not restricted at all, plus
    # the restricted ones this membership is inside.
    scope :for_squadrons_of, lambda { |membership|
      next not_squadron_restricted if membership.blank?

      not_squadron_restricted.or(restricted_to_squadrons_of(membership))
    }
  end

  class_methods do
    # `visibility` is an enum on two of these and a plain string on the third,
    # so the value the scope compares against is asked for rather than assumed.
    def squadron_visibility_value
      defined_enums.key?("visibility") ? :squadron_only : "squadron"
    end

    # Where a record goes when the squadrons it named are gone. The column's
    # own default, so none of the three has to restate what it already
    # declares in the schema.
    def default_visibility
      column_defaults["visibility"]
    end
  end

  def squadron_restricted?
    visibility.to_s == self.class.squadron_visibility_value.to_s
  end

  # Whether this membership is in one of the squadrons named. Reads a loaded
  # association where there is one, so a list that preloaded them asks nothing.
  def visible_to_squadrons_of?(membership)
    return true unless squadron_restricted?
    return false if membership.blank?

    (fleet_squadron_ids & membership.fleet_squadron_ids).any?
  end

  # Its last squadron has been disbanded, so the restriction now names nobody.
  # Falling back is the only answer that leaves the record reachable: left as
  # it is, it is visible to no one and fails validation on its next save.
  def release_squadron_restriction!
    return unless squadron_restricted?
    return if fleet_squadrons.reload.any?

    update_columns(visibility: self.class.default_visibility)
  end

  private def assigned_squadrons_belong_to_the_fleet
    return if fleet_id.blank?

    stray = fleet_squadrons.reject { |squadron| squadron.fleet_id == fleet_id }

    return if stray.empty?

    errors.add(:fleet_squadrons, :not_this_fleets, names: stray.map(&:name).to_sentence)
  end

  private def squadron_visibility_names_a_squadron
    return unless squadron_restricted?
    return if fleet_squadrons.any?

    errors.add(:visibility, :needs_a_squadron)
  end
end
