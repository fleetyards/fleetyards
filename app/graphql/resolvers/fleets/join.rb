# encoding: utf-8
# frozen_string_literal: true

module Resolvers
  module Fleets
    class Join < Resolvers::Base
      def resolve
        fleet = ::Fleet.find_by!(sid: args[:sid])

        membership = fleet.pending_members.create(user_id: current_user.id)

        add_active_record_errors(membership)

        errors.blank?
      end
    end
  end
end
