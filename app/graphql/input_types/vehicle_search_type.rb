# frozen_string_literal: true

InputTypes::VehicleSearchType = ::GraphQL::InputObjectType.define do
  name 'VehicleSearchInput'

  argument :nameCont, types.String, as: :name_cont
  argument :modelNameOrModelDescriptionCont, types.String, as: :ship_name_or_ship_description_cont
  argument :modelOnSaleEq, types.String, as: :ship_on_sale_eq
  argument :modelManufacturerIn, types[!types.String], as: :ship_manufacturer_slug_in
  argument :modelModelRoleIn, types[!types.String], as: :ship_ship_role_slug_in
  argument :modelClassificationIn, types[!types.String], as: :ship_classification_in
  argument :modelProductionStatusIn, types[!types.String], as: :ship_production_status_in
end
