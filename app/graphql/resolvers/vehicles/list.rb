# encoding: utf-8
# frozen_string_literal: true

module Resolvers
  module Vehicles
    class List < Resolvers::Base
      def resolve
        search = user_ships.ransack(args[:q].to_h)

        search.sorts = ['purchased desc', 'name asc', 'created_at desc'] if search.sorts.empty?

        result = search.result
                        .offset(args[:offset])

        result = result.limit(limit) if limit.present?

        result
      end

      private def limit
        return if args[:username].blank?

        [(args[:limit] || 30), 100].min
      end

      private def user
        @user ||= current_user
        @user ||= User.find_by(username: args[:username])
      end

      private def user_ships
        user_ships = user.user_ships
        user_ships = user_ships.purchased if args[:username].present?
        user_ships
      end
    end
  end
end
