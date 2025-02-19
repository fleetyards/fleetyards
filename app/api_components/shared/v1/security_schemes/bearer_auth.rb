# frozen_string_literal: true

module Shared
  module V1
    module SecuritySchemes
      class BearerAuth
        include SchemaConcern

        schema({
          type: :http,
          scheme: :bearer
        })
      end
    end
  end
end
