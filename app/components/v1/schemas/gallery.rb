# frozen_string_literal: true

module V1
  module Schemas
    class Gallery < ::BaseSchema
      data_type :object

      property :id, {type: :string, format: :uuid}
      property :name, {type: :string}
      property :slug, {type: :string}

      required %w[id name slug]
    end
  end
end
