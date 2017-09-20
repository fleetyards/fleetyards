# frozen_string_literal: true

InputTypes::ManufacturerSearchType = ::GraphQL::InputObjectType.define do
  name 'ManufacturerSearchInput'

  argument :nameCont, types.String, as: :name_cont
end
