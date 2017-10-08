# encoding: utf-8
# frozen_string_literal: true

Types::SessionType = GraphQL::ObjectType.define do
  name 'Session'

  field :token, types.String
end
