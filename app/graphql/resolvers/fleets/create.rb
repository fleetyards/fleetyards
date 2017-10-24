# encoding: utf-8
# frozen_string_literal: true

module Resolvers
  module Fleets
    class Create < Resolvers::Base
      def resolve
        fleet = ::Fleet.create(sid: args[:sid])

        add_active_record_errors(fleet)

        fleet.members.create(user_id: current_user.id, admin: true, approved: true) if errors.blank?

        fleet
      end
    end
  end
end
