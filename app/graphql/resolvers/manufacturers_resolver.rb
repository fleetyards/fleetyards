# frozen_string_literal: true

module Resolvers
  class ManufacturersResolver < BaseResolver
    def resolve
      scope = Manufacturer.with_name
      scope = scope.with_model if args[:with_model]

      @q = scope.ransack(args[:q].to_h)

      @q.sorts = 'name asc' if @q.sorts.empty?

      @q.result.offset(args[:offset]).limit(args[:limit])
    end
  end
end
