# encoding: utf-8
# frozen_string_literal: true

module Resolvers
  module Fleets
    class Models < Resolvers::Base
      def resolve
        fleet = current_user.fleets.find_by!(sid: args[:sid])

        search = fleet.models
                      .select(
                        %i[
                          id name slug description length beam height mass cargo
                          crew store_image store_url price on_sale production_status
                          production_note powerplant_size shield_size classification
                          focus rsi_id manufacturer_id ship_role_id created_at updated_at
                        ]
                      )
                      .group(:id)
                      .ransack(args[:q].to_h)

        search.sorts = 'name asc' if search.sorts.empty?

        result = search.result
                       .offset(args[:offset])

        result = result.limit(args[:limit]) if args[:limit].present?

        result.map do |model|
          OpenStruct.new(
            count: fleet.models.where(id: model.id).count,
            model: model
          )
        end
      end
    end
  end
end
