# encoding: utf-8
# frozen_string_literal: true

module Mutations
  Hangar = GraphQL::ObjectType.define do
    field :addToHangar do
      type !Types::UserVehicleType
      description 'Add Ship to Hangar'
      argument :vehicleID, !types.String, as: :vehicle_id
      resolve Resolvers::UserVehicle::New.new
    end
    field :updateMyShip do
      type !Types::UserVehicleType
      description 'Update My Ship'
      argument :userVehicleID, !types.String, as: :user_vehicle_id
      argument :data, InputTypes::UserVehicleType
      resolve Resolvers::UserVehicle::Update.new
    end
    field :removeFromHangar do
      type !Types::UserVehicleType
      description 'Remove Ship from Hangar'
      argument :userVehicleID, !types.String, as: :user_vehicle_id
      resolve Resolvers::UserVehicle::Destroy.new
    end
  end
end
