# frozen_string_literal: true

module Types
  # A jsonb column that still answers to a symbol.
  #
  # `type_data` was a YAML string carrying
  # `!ruby/hash:ActiveSupport::HashWithIndifferentAccess` tags, so every reader
  # got indifferent access for free and several rely on it --
  # `Hardpoint#thruster_class` digs `:thruster_class`, and a plain Hash from
  # jsonb would answer `nil` without raising. Wrapping on the way out keeps the
  # column's new type invisible to everything that reads it.
  class IndifferentJson < ActiveRecord::Type::Json
    def deserialize(value)
      indifferent(super)
    end

    def cast(value)
      indifferent(super)
    end

    private def indifferent(value)
      case value
      when Hash then value.with_indifferent_access
      when Array then value.map { |entry| indifferent(entry) }
      else value
      end
    end
  end
end
