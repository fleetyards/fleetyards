# encoding: utf-8
# frozen_string_literal: true

module Resolvers
  module Fleets
    class List < Resolvers::Base
      def resolve
        if current_user.present?
          Fleet.where.not(id: current_user.fleet_ids).order(name: :asc)
        else
          Fleet.all.order(name: :asc)
        end
      end
    end
  end
end
