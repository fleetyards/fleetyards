# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class AccountUpdateInput
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            username: {type: :string},
            email: {type: :string, format: :email}
          },
          additionalProperties: false
        })
      end
    end
  end
end
