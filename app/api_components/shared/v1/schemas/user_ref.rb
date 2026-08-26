# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # A user by id and handle, neither required. UserRefRequired is the
      # same two fields where the payload always carries them; the split keeps
      # the published contracts as they were.
      class UserRef
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            username: {type: :string}
          }
        })
      end
    end
  end
end
