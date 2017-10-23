# encoding: utf-8
# frozen_string_literal: true

module Resolvers
  module Vehicles
    class PublicCount < Resolvers::Base
      def resolve
        user = User.find_by!(["lower(username) = :value", { value: username }])
        models = user.purchased_ships

        OpenStruct.new(
          total: models.count,
          classifications: models.map(&:classification).uniq.compact.map do |classification|
            OpenStruct.new(
              count: models.where(classification: classification).count,
              name: classification,
              label: I18n.t("filter.ship.classification.items.#{classification}")
            )
          end
        )
      end

      private def username
        args[:username] && args[:username].downcase
      end
    end
  end
end
