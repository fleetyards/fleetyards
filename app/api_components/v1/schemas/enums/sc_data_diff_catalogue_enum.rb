# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class ScDataDiffCatalogueEnum
        include OpenapiRuby::Components::Base

        schema({type: :string, enum: ::ScData::BuildDiff::CATALOGUES.keys})
      end
    end
  end
end
