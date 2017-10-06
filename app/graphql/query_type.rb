# encoding: utf-8
# frozen_string_literal: true

QueryType = GraphQL::ObjectType.new.tap do |root_type|
  root_type.name = 'Query'
  root_type.interfaces = []
  root_type.fields = Utils::FieldCombiner.combine(
    [
      Queries::Vehicles,
      Queries::Manufacturers,
      Queries::Components,
      Queries::Images,
      Queries::Users
    ]
  )
end
