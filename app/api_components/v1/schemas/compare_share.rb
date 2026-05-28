# frozen_string_literal: true

module V1
  module Schemas
    class CompareShare
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        required: [:shortUrl, :longUrl],
        properties: {
          shortUrl: {type: :string, format: :uri, description: "Short shareable URL"},
          longUrl: {type: :string, format: :uri, description: "Canonical compare URL"}
        }
      })
    end
  end
end
