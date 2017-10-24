# encoding: utf-8
# frozen_string_literal: true

module Resolvers
  module Fleets
    class DemoteMember < Resolvers::Base
      def resolve
        fleet = current_user.admin_fleets.find_by!(sid: args[:sid])

        member = fleet.members
                      .includes(:user)
                      .find_by(users: { username: args[:username] })

        return false if current_user.id == member.user_id

        member.present? && member.demote
      end
    end
  end
end
