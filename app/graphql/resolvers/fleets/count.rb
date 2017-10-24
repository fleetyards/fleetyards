# encoding: utf-8
# frozen_string_literal: true

module Resolvers
  module Fleets
    class Count < Resolvers::Base
      def resolve
        fleet = current_user.fleets.find_by!(sid: args[:sid])

        OpenStruct.new(
          total: fleet.models.count,
          classifications: fleet.models.map(&:classification).uniq.compact.map do |classification|
            OpenStruct.new(
              count: fleet.models.where(classification: classification).count,
              name: classification,
              label: I18n.t("filter.ship.classification.items.#{classification}")
            )
          end
        )
      end
    end
  end
end
