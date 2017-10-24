# encoding: utf-8
# frozen_string_literal: true

Types::ResultType = GraphQL::ObjectType.define do
  name 'Result'

  field :success, !types.Boolean
  field :code, !types.String
  field :message, types.String
end
