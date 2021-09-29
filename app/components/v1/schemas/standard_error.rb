# frozen_string_literal: true

module V1
  module Schemas
    class StandardError < ::BaseSchema
      data_type :object

      property :code, {type: :string}
      property :message, {type: :string}

      required %w[code message]
    end
  end
end
