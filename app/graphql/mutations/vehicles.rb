# encoding: utf-8
# frozen_string_literal: true

module Mutations
  Vehicles = GraphQL::ObjectType.define do
    field :addVehicle do
      type !Types::VehicleType
      description 'Create Vehicle and add it to Hangar'
      argument :modelID, !types.String, as: :model_id
      resolve Resolvers::Vehicles::Create.new
    end
    field :updateVehicle do
      type !Types::VehicleType
      description 'Update My Vehicle'
      argument :vehicleID, !types.String, as: :vehicle_id
      argument :data, InputTypes::VehicleType
      resolve Resolvers::Vehicles::Update.new
    end
    field :destroyVehicle do
      type !Types::VehicleType
      description 'Remove Vehicle from Hangar'
      argument :vehicleID, !types.String, as: :vehicle_id
      resolve Resolvers::Vehicles::Destroy.new
    end
  end
end
