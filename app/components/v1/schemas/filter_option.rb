# frozen_string_literal: true

module V1
  module Schemas
    class FilterOption < ::BaseSchema
      data_type :object

      property :name, {type: :string}
      property :value, {type: :string}
      property :category, {type: :string}
      property :icon, {type: :string, nullable: true}

      required %w[name value category]
    end
  end
end
