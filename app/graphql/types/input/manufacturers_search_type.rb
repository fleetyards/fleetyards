# frozen_string_literal: true

Types::Input::ManufacturersSearchType = GraphQL::InputObjectType.define do
  name "ManufacturersSearchInput"

  argument :sorts, types[types.String]
end
