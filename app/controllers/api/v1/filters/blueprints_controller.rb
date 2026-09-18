# frozen_string_literal: true

module Api
  module V1
    module Filters
      class BlueprintsController < ::Api::PublicBaseController
        skip_verify_authorized

        # The materials recipes actually consume, not the whole commodity
        # catalogue. 37 of the 232 commodities appear in a recipe, so a select
        # built from the catalogue would offer 195 options that can only ever
        # come back empty.
        def materials
          @filters = Blueprint.material_filters

          render "api/v1/shared/filters"
        end
      end
    end
  end
end
