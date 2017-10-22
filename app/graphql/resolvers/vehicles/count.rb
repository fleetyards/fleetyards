# encoding: utf-8
# frozen_string_literal: true

module Resolvers
  module Vehicles
    class Count < Resolvers::Base
      def resolve
        if current_user.present?
          current_user.user_ships.count
        else
          user = User.find_by!(["lower(username) = :value", { value: username }])
          user.user_ships.count
        end
      end

      private def username
        args[:username] && args[:username].downcase
      end
    end
  end
end
