# encoding: utf-8
# frozen_string_literal: true

module Resolvers
  module Fleets
    class DeclineJoin < Resolvers::Base
      def resolve
        fleet = current_user.admin_fleets.find_by!(sid: args[:sid])

        pending_member = fleet.pending_members
                              .includes(:user)
                              .find_by(users: { username: args[:username] })

        pending_member.present? && pending_member.destroy
      end
    end
  end
end
