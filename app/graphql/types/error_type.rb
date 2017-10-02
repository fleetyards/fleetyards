# encoding: utf-8
# frozen_string_literal: true

Types::ErrorType = GraphQL::ObjectType.define do
  name 'Error'

  field :code, !types.String do
    resolve ->(obj, _args, _ctx) { obj[:code] }
  end
  field :message, !types.String do
    resolve ->(obj, _args, _ctx) { obj[:message] }
  end
end
