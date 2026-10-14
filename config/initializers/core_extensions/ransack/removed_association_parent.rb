# frozen_string_literal: true

require "ransack"

# Ransack 6.0.0 builds a negative condition on a collection
# (`hangar_groups_not_in`) as a correlated subquery and then drops the join it
# had added for it, parent and all. Every later `result` on the same search
# looks the parent up again, finds nothing, and raises
# `NoMethodError: undefined method 'table' for nil`. The controllers read
# `result` more than once per search, for the ids and again for the order.
#
# Remembering the parent of a dropped join lets the subquery be rebuilt.
unless Ransack::VERSION == "6.0.0"
  raise "ransack #{Ransack::VERSION} is not the version #{__FILE__} patches"
end

module CoreExtensions
  module Ransack
    module RemovedAssociationParent
      def remove_association(association)
        parent = parent_of(association)
        (@removed_association_parents ||= {}.compare_by_identity)[association] ||= parent if parent
        super
      end

      private def parent_of(node)
        super || @removed_association_parents&.[](node)
      end
    end
  end
end

Ransack::ActiveRecord::Context.prepend(CoreExtensions::Ransack::RemovedAssociationParent)
