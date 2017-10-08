# encoding: utf-8
# frozen_string_literal: true

Types::OptionType = GraphQL::ObjectType.define do
  name 'Option'

  field :name, !types.String do
    resolve ->(obj, _args, _ctx) { obj[:name] }
  end
  field :value, !types.String do
    resolve ->(obj, _args, _ctx) { obj[:value] }
  end
  field :icon, types.String do
    resolve ->(obj, _args, _ctx) { obj[:icon] }
  end
end
