# frozen_string_literal: true

InputTypes::UserVehicleSearchType = ::GraphQL::InputObjectType.define do
  name 'UserVehicleSearchInput'

  argument :nameCont, types.String, as: :name_cont
  argument :vehicleNameOrVehicleDescriptionCont, types.String, as: :ship_name_or_ship_description_cont
  argument :vehicleOnSaleEq, types.String, as: :ship_on_sale_eq
  argument :vehicleManufacturerIn, types[!types.String], as: :ship_manufacturer_slug_in
  argument :vehicleVehicleRoleIn, types[!types.String], as: :ship_ship_role_slug_in
  argument :vehicleClassificationIn, types[!types.String], as: :ship_classification_in
  argument :vehicleProductionStatusIn, types[!types.String], as: :ship_production_status_in
end
