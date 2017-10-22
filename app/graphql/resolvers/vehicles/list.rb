# encoding: utf-8
# frozen_string_literal: true

module Resolvers
  module Vehicles
    class List < Resolvers::Base
      def resolve
        if current_user.present?
          hangar
        else
          public_hangar
        end
      end

      private def hangar
        search = current_user.user_ships
                             .ransack(args[:q].to_h)

        search.sorts = ['purchased desc', 'name asc', 'created_at desc'] if search.sorts.empty?

        result = search.result
                       .offset(args[:offset])

        result = result.limit(limit) if limit.present?

        result
      end

      private def public_hangar
        user = User.find_by!(["lower(username) = :value", { value: username }])

        search = user.user_ships.purchased.ransack(args[:q].to_h)

        search.sorts = ['purchased desc', 'name asc', 'created_at desc'] if search.sorts.empty?

        result = search.result
                       .offset(args[:offset])

        result = result.limit(limit) if limit.present?

        result
      end

      private def limit
        return if username.blank?

        [(args[:limit] || 30), 100].min
      end

      private def username
        args[:username] && args[:username].downcase
      end
    end
  end
end
