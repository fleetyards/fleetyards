# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class MarkdownImageCreateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            file: {type: :string, description: "Signed id of an ActiveStorage direct upload"}
          },
          required: %w[file],
          additionalProperties: false
        })
      end
    end
  end
end
