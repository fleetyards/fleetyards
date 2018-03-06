# frozen_string_literal: true

Types::ManufacturerType = GraphQL::ObjectType.define do
  name 'Manufacturer'

  field :name, types.String
  field :slug, types.String
  field :logo, types.String do
    resolve ->(obj, _args, _ctx) do
      obj.logo.small.url if obj.logo.present?
    end
  end
end
