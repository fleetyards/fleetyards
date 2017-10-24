# encoding: utf-8
# frozen_string_literal: true

module Resolvers
  module Vehicles
    class Public < Resolvers::Base
      def resolve
        user = User.find_by!(["lower(username) = :value", { value: username }])

        search = user.user_ships.purchased.ransack(args[:q].to_h)

        search.sorts = ['name asc', 'created_at desc'] if search.sorts.empty?

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
