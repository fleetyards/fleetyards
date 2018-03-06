# frozen_string_literal: true

module Resolvers
  class ModelResolver < BaseResolver
    def resolve
      model = Model.find_by(slug: args[:slug])

      add_not_found_error if model.blank?

      model
    end
  end
end
