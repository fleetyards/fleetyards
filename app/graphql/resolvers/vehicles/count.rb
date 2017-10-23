# encoding: utf-8
# frozen_string_literal: true

module Resolvers
  module Vehicles
    class Count < Resolvers::Base
      def resolve
        models = current_user.ships

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
    end
  end
end
