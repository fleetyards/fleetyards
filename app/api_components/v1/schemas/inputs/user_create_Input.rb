# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class UserCreateInput
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            username: {type: :string},
            email: {type: :string, format: :email},
            password: {type: :string},
            passwordConfirmation: {type: :string},
            saleNotify: {type: :boolean},
            fleetInviteToken: {type: :string}
          },
          additionalProperties: false
        })
      end
    end
  end
end
