# frozen_string_literal: true

InputTypes::UserType = ::GraphQL::InputObjectType.define do
  name 'UserInput'

  argument :username, types.String
  argument :email, types.String
  argument :password, types.String
  argument :passwordConfirmation, types.String, as: :password_confirmation
  argument :rsiHandle, types.String, as: :rsi_handle
  argument :rsiOrg, types.String, as: :rsi_org
  argument :saleNotify, types.Boolean, as: :sale_notify
end
