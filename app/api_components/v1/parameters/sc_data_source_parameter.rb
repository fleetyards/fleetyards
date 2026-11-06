# frozen_string_literal: true

module V1
  module Parameters
    class ScDataSourceParameter
      include OpenapiRuby::Components::Base

      component_type :parameters

      schema({
        name: :scDataSource,
        in: :query,
        description: "Environment of the game data build to read, as listed by /sc-data/sources. " \
          "One that is not available reads the default build.",
        schema: {type: :string},
        required: false
      })
    end
  end
end
