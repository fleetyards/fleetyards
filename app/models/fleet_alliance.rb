# frozen_string_literal: true

# Two fleets who have agreed to share what each has opened to its allies.
#
# The same handshake as `Friendship`, and for the same reasons -- see
# `PartyRelationship`. Two differences worth knowing:
#
# It *is* versioned. An alliance is a governance act: it commits the fleet's
# ships, its stats and its roster to another organisation, and which admin did
# that is exactly the kind of thing the fleet's own audit trail is for. No
# `VersionedItem::ROOTS` entry, though -- a root is the single record a version
# is filed under, and an alliance has two fleets with equal claim to it.
#
# A fleet is soft-deleted, so its alliances outlive it. Every read scopes the
# other side through `.kept`: an alliance with a discarded fleet shows nowhere
# and admits nothing, and is intact if the fleet is restored.
class FleetAlliance < ApplicationRecord
  include PartyRelationship

  # An alliance commits the fleet's ships, its stats and its roster to another
  # organisation, so it is an admin act by default rather than an officer one.
  # Officers can see who the fleet is allied with; members see nothing.
  AVAILABLE_PRIVILEGES = [
    "fleet:allies:read",
    "fleet:allies:create",
    "fleet:allies:delete",
    "fleet:allies:manage"
  ].freeze

  DEFAULT_PRIVILEGES = {
    admin: [],
    officer: ["fleet:allies:read"],
    member: []
  }.freeze

  has_paper_trail on: ::VersionedItem::RECORDED_EVENTS

  belongs_to :requester, class_name: "Fleet"
  belongs_to :addressee, class_name: "Fleet"

  DEFAULT_SORTING_PARAMS = ["created_at desc"]
  ALLOWED_SORTING_PARAMS = [
    "createdAt asc", "createdAt desc",
    "acceptedAt asc", "acceptedAt desc"
  ].freeze

  ransack_alias :state, :aasm_state

  def self.ransackable_attributes(_auth_object = nil)
    %w[state aasm_state created_at updated_at accepted_at declined_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end
end
