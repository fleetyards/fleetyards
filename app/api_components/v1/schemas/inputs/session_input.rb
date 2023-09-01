# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class SessionInput
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            login: {type: :string, description: "Username or email"},
            password: {type: :string},
            rememberMe: {type: :boolean},
            twoFactorCode: {type: :string}
          },
          additionalProperties: false
        })
      end
    end
  end
end
