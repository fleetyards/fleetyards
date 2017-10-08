# encoding: utf-8
# frozen_string_literal: true

module Resolvers
  class Images < Resolvers::Base
    def resolve
      if args[:model_slug].present?
        model_images
      else
        images
      end
    end

    private def model_images
      ship = Ship.find_by!(slug: args[:model_slug])

      ship.images
        .enabled
        .order(created_at: :asc)
        .offset(args[:offset])
          .limit(args[:limit])
    end

    private def images
      scope = Image.enabled
                   .in_gallery
      scope = scope.order(created_at: :desc) unless args[:random]
      scope = scope.order("RANDOM()") if args[:random]
      scope.offset(args[:offset])
           .limit(args[:limit])
    end
  end
end
