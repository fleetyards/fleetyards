# frozen_string_literal: true

InputTypes::ModelSearchType = ::GraphQL::InputObjectType.define do
  name 'ModelSearchInput'

  argument :nameOrDescriptionCont, types.String, as: :name_or_description_cont
  argument :onSaleEq, types.String, as: :on_sale_eq
  argument :manufacturerIn, types[!types.String], as: :manufacturer_slug_in
  argument :modelRoleIn, types[!types.String], as: :ship_role_slug_in
  argument :classificationIn, types[!types.String], as: :classification_in
  argument :productionStatusIn, types[!types.String], as: :production_status_in
  argument :sorts, types[!types.String]
end
