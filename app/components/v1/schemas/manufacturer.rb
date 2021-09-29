# frozen_string_literal: true

module V1
  module Schemas
    class Manufacturer < ::BaseSchema
      data_type :object

      property :name, {type: :string}
      property :slug, {type: :string}
      property :code, {type: :string}
      property :logo, {type: :string, nullable: true}

      property :createdAt, {type: :string, format: "date-time"}
      property :updatedAt, {type: :string, format: "date-time"}

      required %w[name slug createdAt updatedAt]
    end
  end
end
