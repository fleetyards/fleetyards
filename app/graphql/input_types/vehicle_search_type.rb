# frozen_string_literal: true

InputTypes::VehicleSearchType = ::GraphQL::InputObjectType.define do
  name 'VehicleSearchInput'

  argument :name_or_description_cont, types.String
  argument :on_sale_eq, types.String
  argument :manufacturer_in, types[!types.String], as: :manufacturer_slug_in
  argument :vehicle_role_in, types[!types.String], as: :ship_role_slug_in
  argument :classification_in, types[!types.String]
  argument :production_status_in, types[!types.String]
end
