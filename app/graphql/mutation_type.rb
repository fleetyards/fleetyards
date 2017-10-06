# encoding: utf-8
# frozen_string_literal: true

MutationType = GraphQL::ObjectType.new.tap do |root_type|
  root_type.name = 'Mutation'
  root_type.interfaces = []
  root_type.fields = Utils::FieldCombiner.combine(
    [
      Mutations::Sessions,
      Mutations::Hangar
    ]
  )
end
