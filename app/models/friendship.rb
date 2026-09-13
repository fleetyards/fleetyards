# frozen_string_literal: true

# Two users who have agreed to know each other.
#
# One row per unordered pair. `requester` and `addressee` record who asked, so
# an inbox can label a request, and carry no authority once the row is accepted:
# either side may end it, and every read is over both columns.
#
# Deliberately not versioned. A version of this row would hold both user ids --
# a record of who knew whom, kept after one of them deleted their account, which
# is the thing `ErasableVersionsConcern` exists on `User` to prevent. A
# friendship is personal rather than administrative, nothing here is an admin
# act, and the foreign keys cascade for the same reason.
# == Schema Information
#
# Table name: friendships
#
#  id           :uuid             not null, primary key
#  aasm_state   :string           default("pending"), not null
#  accepted_at  :datetime
#  declined_at  :datetime
#  ignored_at   :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  addressee_id :uuid             not null
#  requester_id :uuid             not null
#
# Indexes
#
#  index_friendships_on_addressee_id       (addressee_id)
#  index_friendships_on_pair               (LEAST(requester_id, addressee_id), GREATEST(requester_id, addressee_id)) UNIQUE
#  index_friendships_on_pending_addressee  (addressee_id) WHERE ((aasm_state)::text = 'pending'::text)
#  index_friendships_on_requester_id       (requester_id)
#
# Foreign Keys
#
#  fk_rails_...  (addressee_id => users.id) ON DELETE => cascade
#  fk_rails_...  (requester_id => users.id) ON DELETE => cascade
#
class Friendship < ApplicationRecord
  include PartyRelationship

  belongs_to :requester, class_name: "User"
  belongs_to :addressee, class_name: "User"

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
