# encoding: utf-8
# frozen_string_literal: true

module Resolvers
  class ComponentCategories < Resolvers::Base
    def resolve
      ComponentCategory.all
    end
  end
end
