# encoding: utf-8
# frozen_string_literal: true

module Resolvers
  module Vehicles
    class List < Resolvers::Base
      def resolve
        search = current_user.user_ships.ransack(args[:q].to_h)

        search.sorts = ['purchased desc', 'name asc', 'created_at desc'] if search.sorts.empty?

        result = search.result
                       .offset(args[:offset])

        result = result.limit(args[:limit]) if args[:limit].present?

        result
      end

      private def username
        args[:username] && args[:username].downcase
      end
    end
  end
end
