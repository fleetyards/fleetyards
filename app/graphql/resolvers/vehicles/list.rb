# encoding: utf-8
# frozen_string_literal: true

module Resolvers
  module Vehicles
    class List < Resolvers::Base
      def resolve
        search = user_ships.ransack(args[:q].to_h)

        search.sorts = ['purchased desc', 'name asc', 'created_at desc'] if search.sorts.empty?

        search.result
              .offset(args[:offset])
              .limit(args[:limit])
      end

      private def user
        @user ||= current_user
        @user ||= User.find_by(username: args[:username])
      end

      private def user_ships
        user_ships = user.user_ships
        user_ships = user_ships.purchased if args[:username]
        user_ships
      end
    end
  end
end
