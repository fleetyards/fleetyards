# frozen_string_literal: true

module Locations
  # The reader's friends and fleet mates whose current location is the place or
  # somewhere inside it. Nobody turns up here who is not already shown with
  # their location elsewhere: a friend once the friendship is accepted, as the
  # friends list shows them, and a fleet mate only from a fleet whose roster
  # the reader may read, as the roster shows them.
  class People
    Entry = Struct.new(:user, :friend, :fleets)
    Result = Struct.new(:entries, :total_count)

    READ_MEMBERS = FleetMembership::CAPABILITY_PRIVILEGES.fetch(:read_members)

    # `online` answers for a user the way the reader may see it: true, false, or
    # nil where they get no answer, which ranks with the offline.
    def initialize(location, reader, fleets: true, online: ->(_user) {})
      @location = location
      @reader = reader
      @fleets = fleets
      @online = online
    end

    # Online first, then by name, so a cut keeps who the reader can meet now. A
    # 400-member fleet can all be in one system; the count says how many more.
    def call(limit:)
      friend_ids = friends_here
      fleet_ids_by_user = fleet_mates

      ids = (friend_ids.to_a + fleet_ids_by_user.keys).uniq - [@reader.id]
      return Result.new([], 0) if ids.empty?

      ranked = User.where(id: ids, current_location_id: subtree_ids)
        .select(:id, :normalized_username, :show_online_status)
        .sort_by { |user| [@online.call(user) ? 0 : 1, user.normalized_username] }
      shown_ids = ranked.first(limit).map(&:id)

      fleets = Fleet.where(id: shown_ids.flat_map { Array.wrap(fleet_ids_by_user[it]) }.uniq).index_by(&:id)
      users = User.where(id: shown_ids).includes({current_location: :parent}, avatar_attachment: :blob).index_by(&:id)

      entries = shown_ids.map do |id|
        Entry.new(users[id], friend_ids.include?(id), Array.wrap(fleet_ids_by_user[id]).filter_map { fleets[it] }.sort_by(&:name))
      end

      Result.new(entries, ranked.size)
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
