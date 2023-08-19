# frozen_string_literal: true

module V1
  module Schemas
    class User < UserMinimal
      include SchemaConcern

      schema({
        properties: {}
      })
    end
  end
end
