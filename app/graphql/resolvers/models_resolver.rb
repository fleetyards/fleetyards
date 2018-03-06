# frozen_string_literal: true

module Resolvers
  class ModelsResolver < BaseResolver
    def resolve
      @q = Model.visible.ransack(args[:q].to_h)

      @q.sorts = 'name asc' if @q.sorts.empty?

      @q.result.offset(args[:offset]).limit(args[:limit])
    end
  end
end
