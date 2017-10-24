# encoding: utf-8
# frozen_string_literal: true

module Resolvers
  module Fleets
    class PromoteMember < Resolvers::Base
      def resolve
        fleet = current_user.admin_fleets.find_by!(sid: args[:sid])

        member = fleet.members
                      .includes(:user)
                      .find_by(users: { username: args[:username] })

        member.present? && member.promote
      end
    end
  end
end
