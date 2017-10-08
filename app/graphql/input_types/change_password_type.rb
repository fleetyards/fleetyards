# frozen_string_literal: true

InputTypes::ChangePasswordType = ::GraphQL::InputObjectType.define do
  name 'ChangePasswordInput'

  argument :currentPassword, types.String, as: :current_password
  argument :password, !types.String
  argument :passwordConfirmation, !types.String, as: :password_confirmation
  argument :token, types.String, as: :reset_password_token
end
