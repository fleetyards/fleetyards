# frozen_string_literal: true

module Locations
  # The reader's friends and fleet mates whose current location is the place or
  # somewhere inside it. Nobody turns up here who is not already shown with
  # their location elsewhere: a friend once the friendship is accepted, as the
  # friends list shows them, and a fleet mate only from a fleet whose roster
  # the reader may read, as the roster shows them.
  class People
    Entry = Struct.new(:user, :friend, :fleets)

    READ_MEMBERS = FleetMembership::CAPABILITY_PRIVILEGES.fetch(:read_members)

    def initialize(location, reader, friends: true, fleets: true)
      @location = location
      @reader = reader
      @friends = friends
      @fleets = fleets
    end

    def call
      friend_ids = @friends ? friends_here : Set.new
      fleet_ids_by_user = fleet_mates

      ids = (friend_ids.to_a + fleet_ids_by_user.keys).uniq - [@reader.id]
      return [] if ids.empty?

      fleets = Fleet.where(id: fleet_ids_by_user.values.flatten.uniq).index_by(&:id)

      User.where(id: ids, current_location_id: subtree_ids)
        .includes({current_location: :parent}, avatar_attachment: :blob)
        .order(:normalized_username)
        .map do |user|
          Entry.new(user, friend_ids.include?(user.id), Array.wrap(fleet_ids_by_user[user.id]).filter_map { fleets[it] }.sort_by(&:name))
        end
    end

    private def friends_here
      User.where(id: Friendship.partner_ids_for(@reader), current_location_id: subtree_ids).pluck(:id).to_set
    end

    private def fleet_mates
      return {} unless @fleets

      fleet_ids = @reader.kept_fleet_memberships.accepted.includes(:fleet_role)
        .select { |membership| membership.has_access?(READ_MEMBERS) }
        .map(&:fleet_id)
      return {} if fleet_ids.empty?

      FleetMembership.kept.accepted
        .where(fleet_id: Fleet.kept.where(id: fleet_ids).select(:id))
        .joins(:user).where(users: {current_location_id: subtree_ids})
        .pluck(:user_id, :fleet_id)
        .group_by(&:first)
        .transform_values { |pairs| pairs.map(&:last) }
    end

    # The place and everything below it. UNION rather than UNION ALL, so a loop
    # in the parent links ends the walk instead of running it forever.
    private def subtree_ids
      @subtree_ids ||= Location.find_by_sql([<<~SQL.squish, @location.id]).map(&:id)
        WITH RECURSIVE subtree(id) AS (
          SELECT id FROM locations WHERE id = ?
          UNION
          SELECT locations.id FROM locations JOIN subtree ON locations.parent_id = subtree.id
        )
        SELECT id FROM subtree
      SQL
    end
  end
end
