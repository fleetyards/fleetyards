# encoding: utf-8
# frozen_string_literal: true

Types::VehicleType = GraphQL::ObjectType.define do
  name 'Vehicle'
  description 'Default Vehicle Type for Ships and Ground Vehicles'

  field :name, !types.String
  field :slug, !types.String
  field :description, types.String
  field :length, types.String
  field :beam, types.String
  field :height, types.String
  field :mass, types.String
  field :cargo, types.String
  field :netCargo, types.String do
    resolve ->(obj, _args, _ctx) { obj.addition && obj.addition.net_cargo }
  end
  field :crew, types.String
  field :storeImage, !types.String, property: :store_image
  field :storeURL, !types.String, property: :store_url
  field :price, types.String
  field :onSale, !types.Boolean, property: :on_sale
  field :productionStatus, types.String, property: :production_status
  field :productionNote, types.String, property: :production_note
  field :powerplantSize, types.String, property: :powerplant_size
  field :shieldSize, types.String, property: :shield_size
  field :classification, types.String
  field :focus, types.String
  field :rsiID, !types.String, property: :rsi_id

  field :manufacturer, Types::ManufacturerType
  field :role, Types::VehicleRoleType, property: :ship_role
  # field :hardpoints, types[!Types::HardpointType]
  field :images, types[!Types::ImageType]
  # field :videos, types[!Types::VideoType]

  field :createdAt, !types.String, property: :created_at
  field :updatedAt, !types.String, property: :updated_at
end
