# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Enums
        # Admin only, like the size: the public payload states access as a
        # label, and an enum on a public response turns every value added later
        # into a schema warning the gate fails on.
        class DockAccessEnum
          include OpenapiRuby::Components::Base

          schema({
            type: :string,
            enum: ::Dock.accesses.keys,
            "x-enumNames": ::Dock.accesses.keys.map { |v| transform_enum_key(v) }
          })
        end
      end
    end
  end
end
