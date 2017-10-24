# encoding: utf-8
# frozen_string_literal: true

module Resolvers
  module Fleets
    class Destroy < Resolvers::Base
      def resolve
        fleet = current_user.admin_fleets.find_by!(sid: args[:sid])

        fleet.destroy

        fleet
      end
    end
  end
end
