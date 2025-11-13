# frozen_string_literal: true

module Shared
  module V1
    module SecuritySchemes
      class BearerAuth
        include Rswag::SchemaComponents::Component

        schema({
          type: :http,
          scheme: :bearer
        })
      end
    end
  end
end
