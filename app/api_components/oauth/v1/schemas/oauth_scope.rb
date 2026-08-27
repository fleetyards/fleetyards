# frozen_string_literal: true

module Oauth
  module V1
    module Schemas
      class OauthScope
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            description: {type: :string}
          },
          required: %w[name description]
        })
      end
    end
  end
end
