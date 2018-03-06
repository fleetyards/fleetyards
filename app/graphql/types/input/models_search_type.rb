# frozen_string_literal: true

Types::Input::ModelsSearchType = GraphQL::InputObjectType.define do
  name "ModelsSearchInput"

  argument :nameOrDescriptionCont, types.String, as: :name_or_description_cont
  argument :onSaleEq, types.String, as: :on_sale_eq
  argument :manufacturerSlugIn, types[types.String], as: :manufacturer_slug_in
  argument :classificationIn, types[types.String], as: :classification_in
  argument :focusIn, types[types.String], as: :focus_in
  argument :productionStatusIn, types[types.String], as: :production_status_in
  argument :sorts, types[types.String]
end
