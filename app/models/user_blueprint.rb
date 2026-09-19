# frozen_string_literal: true

# A recipe somebody holds.
#
# The row is the whole statement: it exists, therefore they have it. What a
# blueprint can still be used for is an announced game feature that has not
# shipped, so nothing here counts anything -- see the migration.
#
# This is also where the fleet privilege for the surface lives. There is no
# `FleetBlueprint` record to hang it on, because a fleet reads its members'
# markers through a join rather than through a denormalised copy of them, and
# the privilege has to be declared on the record being shown.
# == Schema Information
#
# Table name: user_blueprints
#
#  id           :uuid             not null, primary key
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  blueprint_id :uuid             not null
#  user_id      :uuid             not null
#
# Indexes
#
#  index_user_blueprints_on_blueprint_id        (blueprint_id)
#  index_user_blueprints_on_user_and_blueprint  (user_id,blueprint_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (blueprint_id => blueprints.id) ON DELETE => cascade
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
#
class UserBlueprint < ApplicationRecord
  belongs_to :user
  belongs_to :blueprint

  validates :blueprint_id, uniqueness: {scope: :user_id}

  # Read and nothing else. Every other group carries create/update/delete
  # because the fleet owns the records; these belong to the members, and the
  # fleet neither writes nor removes them. A `:manage` privilege here would
  # grant nothing, and the roles page omits the group's manage toggle when
  # there is none.
  AVAILABLE_PRIVILEGES = [
    "fleet:blueprints:read"
  ].freeze

  DEFAULT_PRIVILEGES = {
    admin: [],
    officer: ["fleet:blueprints:read"],
    member: ["fleet:blueprints:read"]
  }.freeze
end
