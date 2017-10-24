# encoding: utf-8
# frozen_string_literal: true

module Resolvers
  module Fleets
    class Models < Resolvers::Base
      def resolve
        fleet = current_user.fleets.find_by!(sid: args[:sid])

        search = fleet.models.ransack(args[:q].to_h)

        search.sorts = 'name asc' if search.sorts.empty?

        result = search.result
                       .offset(args[:offset])

        result = result.limit(args[:limit]) if args[:limit].present?

        result.group_by(&:name).map do |(_, models)|
          OpenStruct.new(
            count: models.size,
            model: models.first
          )
        end
      end
    end
  end
end
